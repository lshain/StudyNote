Shader "Custom/Specular/Texture/NormalMapping_World"
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

				// 存储 切线空间 到 世界空间 的变换矩阵
				// 同时为了充分利用 差值寄存器 我们把 世界空间 下的 顶点位置 存储在这些变量的 w分量里面
				float4 TtoW0 : TEXCOORD0;
				float4 TtoW1 : TEXCOORD1;
				float4 TtoW2 : TEXCOORD2;

				// 存储纹理坐标
				float4 uv : TEXCOORD3;
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

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				// Compute the matrix that transform dir from tangent space to world space
				// Put the world position in w component for optimization
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
				
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				//切线空间下 计算 漫反射 + 高光 + 法线凹凸 贴图
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// Get the texel in the normal map
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
		
				bump = bump * _BumpScale;

				// x^2 + y^2 + z^2 = 1
				// z = sqrt( 1 - ( x^2 + y^2 ) )
				// dot(tangentNormal.xy, tangentNormal.xy) = (x, y)(x, y) = x^2 + y^2
				bump.z = sqrt(1.0 - saturate(dot(bump.xy, bump.xy)));

				// Transform the normal form tangent space to world space
				// 使用 转换矩阵 每一行 与 向量的 点积，来进行 变换
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));

				// tex2D 根据纹理uv 取出纹理颜色值
				fixed3 albedo = tex2D(_MainTex, i.uv.xy);
	
				// 使用_Diffuse颜色 整体控制 模型色调
				albedo = albedo * _Diffuse.rgb;

				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump, worldLightDir));

				// Get the half direction in world space
				fixed3 halfDir = normalize(worldViewDir + worldLightDir);

				// Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, bump)), _Gloss);

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}

	Fallback "Specular"
}
