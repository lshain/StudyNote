// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Diffuse/Diffuse_PrePixel_HalfLambert"
{
	Properties
	{
		_DiffuseColor("DiffuseColor", Color) = (1.0, 1.0, 1.0, 1.0)
	}

	SubShader
	{
		//Tags { "RenderType"="Opaque" }
		//LOD 100

		Pass
		{
			// 只有正确定义了LightMode 才能得到一些Unity的内置光照变量，如_LightColor0
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM
			
			// 说明顶点和片元着色器的函数名字
			#pragma vertex vert
			#pragma fragment frag
			
			// 引入Lighting，才能访问Unity的内置光照变量。
			#include "Lighting.cginc"
			
			#include "UnityCG.cginc"

			struct a2v
			{
				// 为了访问模型顶点坐标 需要使用 POSITION 语义定义一个变量，告诉Unity从应用数据中传入顶点坐标
				float4 vertex : POSITION;

				// 为了访问模型顶点法线 需要使用 NORMAL 语义定义一个变量，告诉Unity从应用数据中传入顶点法线
				float4 normal : NORMAL;
			};

			struct v2f
			{
				// 为了访问片元坐标 需要使用 SV_POSITION 语义定义一个变量，它的值由顶点坐标插值得到
				float4 vertex : SV_POSITION;
			
				// 存储顶点着色器中计算的法线，它的值由顶点法线插值得到
				fixed3 worldNormal : TEXCOORD0;
			};

			fixed4 _DiffuseColor;
			
			v2f vert (a2v v)
			{
				v2f o;

				// Transform the vertex from object space to projection space
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);

				// Transform the normal from object space to world space
				// _Object2World 模型空间到世界空间的转换矩阵
				// _World2Object 世界空间到模型空间的转换矩阵
				// 
				// v.normal在模型空间下，需要转换到世界空间中
				// 转换方法可以使用 顶点变换矩阵 的 逆转置矩阵 对法线进行相同的变换
				// _World2Object 为 _Object2World 的逆矩阵
				//
				// 对于向量来说 V 或者 V的转置V^T 他们的分量 值 是相同的，对于我们使用来说木有区别
				//
				// mul((float3x3)_World2Object^T, v.normal)^T == mul(v.normal^T, (float3x3)_World2Object)
				// 交换 mul函数两个参数的位置，可以避免计算变换矩阵的转置矩阵  
				//
				// 上面相等的意思 只是 表示 这两种乘法 得到的 向量 各分量值 相同
				//
				// 由于是变换发现，所以3*3的矩阵就行了，使用(float3x3) 截取出 矩阵的前3行3列
				o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// Get ambient term
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				// Get the light direction in world space
				// _WorldSpaceLightPos0当场景中只有一个平行光时，可以用这个拿到光源方向
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

				fixed3 worldNormal = normalize(i.worldNormal);

				// Compute diffuse term 利用漫反射数学公式计算漫反射光照颜色
				// Cdiff = Clight * Mdiff * max(0, dot(worldNormal, worldLight))
				// _LightColor0光源颜色
				fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
				fixed3 diffuse = _LightColor0.rgb * _DiffuseColor * halfLambert;

				// 最终的颜色由漫反射颜色和环境光颜色的叠加
				fixed3 color = ambient + diffuse;

				return fixed4(color, 1.0);
			}

			ENDCG
		}
	}

	Fallback "Diffuse"
}
