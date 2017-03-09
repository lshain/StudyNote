Shader "Custom/Texture/SingleColor" 
{
	// 属性
	Properties
	{
		//定义一个颜色
		_Color("Main Color", Color) = (1, 0.5, 0.5, 1)
	}

	// 子shader
	SubShader
	{
		Pass
		{
			Material
			{
				//显示该颜色
				Diffuse[_Color]
			}
		
			//打开光照开关，即接受光照
			Lighting On
		}
	}
}
