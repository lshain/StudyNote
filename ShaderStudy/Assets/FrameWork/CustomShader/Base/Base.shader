Shader "Custom/Template/Base"
{
	Properties
	{
		// 单值
		_Int ("Int", Int) = 2
		_Float ("Float", Float) = 1.5
		_Range ("Range", Range(0.1, 377)) = 20

		// 向量或者颜色， 就是float4
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
		_Vector ("Vector", Vector) = (1.0, 1.0, 1.0, 1.0)

		// 贴图，纹理
		_2D("2D Texture", 2D) = "bump" {}
		_3D("3D Texture", 3D) = "black" {}
		_Cube("Cube Texture", CUBE) = "white" {}
	}

	SubShader
	{
		//Tags { "RenderType"="Opaque" }
		//LOD 100

		Pass
		{
			//Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct a2v
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};

			float _Int;
			float _Float;
			float _Range;

			float4 _Color;
			float4 _Vector;

			sampler2D _2D;
			sampler3D _3D;
			samplerCUBE _Cube;

			v2f vert (a2v v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return fixed4(1, 1, 1, 1);
			}
			ENDCG
		}
	}

	//Fallback "Diffuse"
}
