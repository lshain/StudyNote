﻿Shader "Custom/Specular/Texture/SingleTexture"
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

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;

				// 存储模型的 第一组 纹理坐标
				float4 texcoord : TEXCOORD0; 
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;

				// 存储纹理坐标
				float2 uv : TEXCOORD2;
			};

			v2f vert (a2v v)
			{
				v2f o;

				// Transform the vertex from object space to projection space
				//o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);

				// Transform the normal from object space to world space
				//o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				// 计算uv坐标
				// o.uv = TRANSFROM_TEX(v.texcoord, _MainTex)
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// tex2D 根据纹理uv 取出纹理颜色值
				fixed3 albedo = tex2D(_MainTex, i.uv);
	
				// 使用_Diffuse颜色 整体控制 模型色调
				albedo = albedo * _Diffuse.rgb;

				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				fixed3 worldNormal = normalize(i.worldNormal);

				// Get the light direction in world space
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal, worldLightDir));

				// Get the view direction in world space
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				// Get the half direction in world space
				fixed3 halfDir = normalize(viewDir + worldLightDir);

				// Compute specular term
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color, 1.0);
			}
			ENDCG
		}
	}

	Fallback "Specular"
}
