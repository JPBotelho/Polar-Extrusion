Shader "Unlit/Extrusion"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Gradient ("Gradient", 2D) = "white" {}
		_Color ("Color", Color) = (1, 1, 1, 1)

		_AngleScrollSpeed ("Angle Speed", Range (0, 5)) = 1
		_DistanceExtrusionSpeed ("Distance Speed", Range (0, 5)) = 1

		_DistanceSpeedGradient ("Distance Speed Gradient", Range (0, 5)) = 1

		[MaterialToggle] _Inwards ("Inwards", Float) = 0
		[MaterialToggle] _GradientInwards ("Gradient Inwards", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		//Cull Off //Uncomment this line to render double-sided geometry

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
						
			#include "UnityCG.cginc"

			#define pi 3.141592653589

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			

			sampler2D _MainTex;
			sampler2D _Gradient;
			fixed4 _Color;

			float4 _MainTex_ST;

			fixed _AngleScrollSpeed;
			fixed _DistanceExtrusionSpeed;
			
			fixed _AngleScrollSpeedGradient;
			fixed _DistanceSpeedGradient;

			bool _Inwards;
			bool _GradientInwards;

			float2 CartesianToPolar (in float2 uv)
			{
				float angle = atan2 (uv.y, uv.x) / (2 * pi); // Converts (-pi, pi) radians to (-0.5, 0.5) radians
				float dist = log(dot(uv, uv)) * 0.5; //Uses a log curve to maintain shape
				//float dist = length (uv); // Uses Pythagorean length which messes up shape, so we use a log curve instead

				return float2(angle, dist);
			}

			float4 GradientFromPolar (in float2 polar)
			{
				float4 gradient = float4(ddx(polar), ddy(polar));
				gradient.xz = frac(gradient.xz + 1.5) - 0.5;

				return gradient;
			}


			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);

				o.uv = v.uv;
				o.uv -= 0.5;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float2 textureUV = CartesianToPolar (i.uv);
				float2 gradientUV = textureUV;

				float2 extrusion = float2 (_AngleScrollSpeed, _DistanceExtrusionSpeed);
				float2 gradientExtrusion = float2(_AngleScrollSpeedGradient, _DistanceSpeedGradient);

				textureUV *= _MainTex_ST.xy; // Multiply the polar coordinates by texture tiling properties

				gradientUV += gradientExtrusion * _Time.y * _GradientInwards;
				gradientUV -= gradientExtrusion * _Time.y * !_GradientInwards;

				textureUV += extrusion * _Time.y * _Inwards;
				textureUV -= extrusion * _Time.y * !_Inwards;

				float4 gradient = GradientFromPolar(textureUV);

				// Uses tex2dgrad to fix a pixel-wide artifact with using atan2
				fixed4 texSample = tex2Dgrad(_MainTex, textureUV, _MainTex_ST.xy * gradient.xy, _MainTex_ST.xy * gradient.zw);

				fixed4 gradientSample = tex2D (_Gradient, gradientUV) * _Color;

				return texSample * gradientSample;
			}
			ENDCG
		}
	}
}
