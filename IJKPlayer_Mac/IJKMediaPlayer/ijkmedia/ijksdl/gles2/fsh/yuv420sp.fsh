//
//  Shader.vsh
//  GLSLTest
//
//  Created by Zenny Chen on 4/11/10.
//  Copyright GreenGames Studio 2010. All rights reserved.
//

// 在OpenGL3.2 Core Profile中，版本号必须显式地给出



//
//#include "ijksdl/gles2/internal.h"
//
//static const char g_shader[] = IJK_GLES_STRING(
//    precision highp float;
//
//    varying     highp vec2 vv2_Texcoord;
//                                                // Texcoord means coord for texture
//    varying     vec3  vHSV;
//    uniform     mat3  um3_ColorConversion;      // para of convention of color eg. YUV=>RGB
//
//    uniform     highp  sampler2D us2_SamplerX;   // Y color
//    uniform     highp  sampler2D us2_SamplerY;   // U
//    uniform     highp  sampler2D us2_SamplerZ;   // V
//
//    uniform     highp  float mobile_res;
//    uniform     highp  float screenWidth;
//    uniform     highp  float screenHeight;
//
//    uniform     highp  float diff_x;   //SBS 左右间距
//    uniform     highp  float diff_y;   //not in used
//    uniform     highp  float lenswidth;   //膜片宽度
//    uniform     highp  float rate_y;   //not in used
//    uniform     highp  float xtimes;   //水平坐标 0.5 means 2times
//    uniform     highp  float ytimes;   //垂直坐标 0.5 means 2times
//    uniform     highp  float rate;     //膜片斜率
//    uniform     int _test;             //switch to test
//    uniform     highp  float brightness;
//    uniform     highp  float contrast;
//    uniform     highp  float saturation;
//
//    // Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
//    const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
//
//    highp vec3 yuv;
//    highp vec3 rgb;
//    highp vec4 pxColor;
//
//    lowp float luminance = dot(rgb, luminanceWeighting);
//    lowp vec3 greyScaleColor = vec3(luminance);
//
//   vec4 getPixelColor(float xPos,float yPos)
//   {
//       yuv.x = texture2D(us2_SamplerX, vec2(xPos, yPos)).r - (16.0 /255.0);
//       yuv.y = texture2D(us2_SamplerY, vec2(xPos, yPos)).r - 0.5;
//       yuv.z = texture2D(us2_SamplerZ, vec2(xPos, yPos)).r - 0.5;
//       rgb    = um3_ColorConversion * yuv +vec3(brightness) ;
//       pxColor = vec4(mix(greyScaleColor, rgb,  saturation), 1);
//       pxColor = vec4(((rgb.rgb - vec3(0.5)) * contrast + vec3(0.5)), 1);
//       pxColor = vec4(rgb, 1);
//       return pxColor;
//  }
//
//    void main()
//    {
//        lowp float  saturation  = 1.5;  //饱和度
//        lowp float  contrast    = 1.2; //对比度
//        //饱和度
//        highp   vec2 textcoord;
//        textcoord = vv2_Texcoord;
//        highp float leftX  = textcoord.x * xtimes;
//        highp float rightX = textcoord.x * xtimes + diff_x + 0.5;
//        highp float leftY  = textcoord.y;
//        highp float rightY = leftY;
//
////        //rate = -6.19
//        highp float uK;   //斜率
//        highp float uD;   //设置宽度   private double d = 2.59379992;
//        highp float uM;   //设置移动距离
//
//        highp float PI = 3.1415926535898;
//
//        uK = tan(PI/180.00 * (144.141204+6.2800+rate));
////  uK = -0.56758965845;
//
//        uD = 2.59379992-lenswidth ;
//        uM = 0.0;
//
//        highp float w1 ;
//        highp float w2 ;
//    if(_test==1){
//            w1 = mod((abs((uK * ((textcoord.x)*screenWidth)) - (2.0-textcoord.y)*screenHeight + uM) / sqrt(uK * uK + 1.0)),uD);
//            w2 =  uD - w1;
//            w1<w2?gl_FragColor = getPixelColor(leftX,leftY):gl_FragColor = getPixelColor(rightX,rightY);
//        }
//    else
//        {
//            w1 = mod((abs((uK * ((textcoord.x)*screenWidth)) - (2.0-textcoord.y)*screenHeight + uM) / sqrt(uK * uK + 1.0)),uD);
//            w2 =  uD - w1;
//            w1<w2?gl_FragColor =  vec4(1.0, 0.0, 0.0, 1.0):gl_FragColor =  vec4(0.0, 1.0, 0.0, 1.0);
//        }
//    }
//);
//
//const char *IJK_GLES2_getFragmentShader_yuv420p()
//{
//    return g_shader;
//}



#version 410

precision highp float;
in          highp vec2 vv2_Texcoord;
uniform     mat3 um3_ColorConversion;

uniform     highp  sampler2D us2_SamplerX;   // Y color
uniform     highp  sampler2D us2_SamplerY;   // U
uniform     highp  sampler2D us2_SamplerZ;   // V

uniform     highp  float mobile_res;
uniform     highp  float screenWidth;
uniform     highp  float screenHeight;
                                           
uniform     highp  float diff_x;   //SBS 左右间距
uniform     highp  float diff_y;   //not in used
uniform     highp  float lenswidth;   //膜片宽度
uniform     highp  float rate_y;   //not in used
uniform     highp  float xtimes;   //水平坐标 0.5 means 2times
uniform     highp  float ytimes;   //垂直坐标 0.5 means 2times
uniform     highp  float rate;     //膜片斜率
uniform     int _test;             //switch to test
uniform     highp  float brightness;
uniform     highp  float contrast;
uniform     highp  float saturation;
                                           
// Values from "Graphics Shaders: Theory and Practice" by Bailey and Cunningham
const mediump vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
                                           
highp vec3 yuv;
highp vec3 rgb;
highp vec4 pxColor;
                                           
lowp float luminance = dot(rgb, luminanceWeighting);
lowp vec3 greyScaleColor = vec3(luminance);
          
vec4 getPixelColor(float xPos,float yPos)
{
    
   yuv.x  = (texture(us2_SamplerX,  vec2(xPos, yPos)).r  - (16.0 / 255.0));
   yuv.yz = (texture(us2_SamplerY,  vec2(xPos, yPos)).rg - vec2(0.5, 0.5));
    
//   yuv.x = texture2D(us2_SamplerX, vec2(xPos, yPos)).r - (16.0 /255.0);
//   yuv.y = texture2D(us2_SamplerY, vec2(xPos, yPos)).r - 0.5;
//   yuv.z = texture2D(us2_SamplerZ, vec2(xPos, yPos)).r - 0.5;
   rgb    = um3_ColorConversion * yuv +vec3(brightness) ;
   pxColor = vec4(mix(greyScaleColor, rgb,  saturation), 1);
   pxColor = vec4(((rgb.rgb - vec3(0.5)) * contrast + vec3(0.5)), 1);
   pxColor = vec4(rgb, 1);
   return pxColor;
}
//
//uniform   lowp  sampler2D us2_SamplerX;
//uniform   lowp  sampler2D us2_SamplerY;
out vec4 colorOut;


void main()
{
//    mediump vec3 yuv;
//    lowp    vec3 rgb;
//
//    yuv.x  = (texture(us2_SamplerX,  vv2_Texcoord).r  - (16.0 / 255.0));
//    yuv.yz = (texture(us2_SamplerY,  vv2_Texcoord).rg - vec2(0.5, 0.5));
//    rgb = um3_ColorConversion * yuv;
//
//
//
    lowp float  saturation  = 1.5;  //饱和度
    lowp float  contrast    = 1.2; //对比度
    //饱和度
    highp   vec2 textcoord;
    textcoord = vv2_Texcoord;
    highp float leftX  = textcoord.x * xtimes;
    highp float rightX = textcoord.x * xtimes + diff_x + 0.5;
    highp float leftY  = textcoord.y;
    highp float rightY = leftY;

//        //rate = -6.19
    highp float uK;   //斜率
    highp float uD;   //设置宽度   private double d = 2.59379992;
    highp float uM;   //设置移动距离
    
    highp float PI = 3.1415926535898;

    uK = tan(PI/180.00 * (144.141204+6.2800+rate));
//  uK = -0.56758965845;
    
    uD = 2.59379992-lenswidth ;
    uM = 0.0;

    highp float w1 ;
    highp float w2 ;
    
    if(_test==1){
            w1 = mod((abs((uK * ((textcoord.x)*screenWidth)) - (2.0-textcoord.y)*screenHeight + uM) / sqrt(uK * uK + 1.0)),uD);
            w2 =  uD - w1;
            w1<w2?colorOut = getPixelColor(leftX,leftY):colorOut = getPixelColor(rightX,rightY);
        }
    else
        {
            w1 = mod((abs((uK * ((textcoord.x)*screenWidth)) - (2.0-textcoord.y)*screenHeight + uM) / sqrt(uK * uK + 1.0)),uD);
            w2 =  uD - w1;
            w1<w2?colorOut =  vec4(1.0, 0.0, 0.0, 1.0):colorOut =  vec4(0.0, 1.0, 0.0, 1.0);
        }
    
    
//    colorOut = vec4(rgb, 1);
}
