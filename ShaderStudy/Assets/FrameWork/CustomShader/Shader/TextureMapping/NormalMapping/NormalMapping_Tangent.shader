Shader "Custom/Specular/Texture/NormalMapping_Tangent"
{
	Properties
	{
		// 控制漫反射颜色
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		// 控制高光反射颜色
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		// 控制高光区域大小
		_Gloss("Gloss", Range(8.0, 255)) = 20

		// 模型纹理
		_MainTex("Main Tex", 2D) = "white" {}
		// 法线纹理
		// bump 是 Unity 内置的法线纹理，当没有提供任何法线纹理时，bump就对应了模型自带的法线信息
		_BumpMap("Normal Tex", 2D) = "bump" {}
		// 用于控制凹凸程度
		_BumpScale("Bump Scale", Float) = 1.0
	}

	SubShader
	{
		Pass
		{
			Tags { "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"
			#include "UnityCG.cginc"

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			sampler2D _MainTex;
			// 需要为纹理类型的属性声明一个float4的变量，变量名固定， 纹理变量名_ST，
			// ST是scale和translation的缩写
			// _MainTex_ST中存储了 纹理的 缩放 和 平移 数据。
			// _MainTex_ST.xy 存储的是缩放值
			// _MainTex_ST.zw 存储的是偏移值
			// 这些值可以在材质面板上面调节(Tiling对应 缩放， Offset对应 偏移)
			float4 _MainTex_ST;

			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			float _BumpScale;

			struct a2v
			{
				// 顶点坐标
				float4 vertex : POSITION;
				// 法线
				float3 normal : NORMAL;
				// 切线 tangent.xyz 为切线向量分量 tangent.w分量用于决定 切线空间中的 副切线(y轴) 方向。 
				// 切线空间中  切线方向为(x轴)
				// 切线空间中  法线方向为(z轴)
				// 切线空间中  副切线(y轴)
				float4 tangent : TANGENT;

				// 存储模型的 第一组 纹理坐标
				float4 texcoord : TEXCOORD0; 
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;

				// 存储 切线空间中 光照方向
				float3 lightDir : TEXCOORD0;
				// 存储 切线空间中 视角方向
				float3 viewDir : TEXCOORD1;

				// 存储纹理坐标
				float4 uv : TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;

				// Transform the vertex from object space to projection space
				//o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);

				// 计算uv坐标
				// 存储MainTex uv坐标
				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				// 存储BumpMap uv坐标
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;

				// 计算副切线(切线空间y轴)
				float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
				
				// Construct a matrix which transform vectors from object space to tangent space
				// or use the built-in macro TANGENT_SPACE_ROTATION;
				// 利用 模型空间 下 切线空间的 3个坐标轴 矢量 构造 变换矩阵
				float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);

				// ObjSpaceLightDir
				// 输入 模型空间 顶点 
				// 输出 模型空间中 顶点光照方向

				// ObjSpaceViewDir
				// 输入 模型空间 顶点 
				// 输出 模型空间中 顶点视角方向

				// 计算 切线空间下的 光照方向 和 视角方向
				o.lightDir = mul(rotation, ObjSpaceLightDir(o.vertex)).xyz;
				o.viewDir = mul(rotation, ObjSpaceViewDir(o.vertex)).xyz;
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//切线空间下 计算 漫反射 + 高光 + 法线凹凸 贴图

				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				// Get the texel in the normal map
				fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
				fixed3 tangentNormal;

				// If the texture is not marked as "Normal map"
				// tangentNormal.xy = (packedNormal.xy * 2 - 1)
	
				// Or marked as "Normal map"
				tangentNormal = UnpackNormal(packedNormal);
				tangentNormal = tangentNormal * _BumpScale;

				// x^2 + y^2 + z^2 = 1
				// z = sqrt( 1 - ( x^2 + y^2 ) )
				// dot(tangentNormal.xy, tangentNormal.xy) = (x, y)(x, y) = x^2 + y^2
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

				// tex2D 根据纹理uv 取出纹理颜色值
				fixed3 albedo = tex2D(_MainTex, i.uv.xy);
	
				// 使用_Diffuse颜色 整体控制 模型色调
				albedo = albedo * _Diffuse.rgb;

				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal, tangentLightDir));

				// Get the half direction in world space
				fixed3 halfDir = normalize(tangentViewDir + tangentLightDir);

				// Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, tangentNormal)), _Gloss);

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}

	Fallback "Specular"
}
