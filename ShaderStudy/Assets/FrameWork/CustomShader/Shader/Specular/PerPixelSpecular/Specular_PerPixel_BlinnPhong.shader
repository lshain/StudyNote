﻿Shader "Custom/Specular/Specular_PerPixel_BlinnPhong"
{
	Properties
	{
		// 控制漫反射颜色
		_Diffuse("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
		// 控制高光反射颜色
		_Specular("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
		// 控制高光区域大小
		_Gloss("Gloss", Range(8.0, 255)) = 20
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

			struct a2v
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
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

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldNormal = normalize(i.worldNormal);

				// Get the light direction in world space
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				// Compute diffuse term
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

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
