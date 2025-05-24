#import "template/template.typ": *

#show: xdudoc.with()


// 这里包括摘要和目录
#front-matter[
  #abstract(
    ch-keywords: [*虚幻引擎* ~~~ *跨平台游戏开发* ~~~~ ],
    en-keywords: [Unreal Engine ~~~ Cross-Platform Game Development ],
  )[
    跨平台开发正成为游戏行业的一大课题。跨平台游戏指在多个平台（如个人电脑、手机、游戏主机）上具备相同内容和游玩体验的游戏。虚幻引擎作为成熟商业引擎，提供了成熟基建，便于开发者在此基础上开发跨平台部署的产品。本文从三个跨平台游戏开发存在的子课题出发，设计与跨平台渲染管线、新一代输入处理工具和资产及碰撞烘焙技术相关的模块，并对其进行测试和检验。最后总结模块设计和实现中的不足，探索更高效，成本更低的跨平台游戏开发策略。
  ][
    Cross-platform development is becoming a major issue in the game industry. Cross-platform games refer to games that have the same content and playing experience on multiple platforms (e.g., PCs, cell phones, game consoles). Unreal Engine, as a mature commercial engine, provides a mature infrastructure on which developers can easily develop products for cross-platform deployment. In this paper, we design modules related to cross-platform rendering pipeline, next-generation input processing tools, and asset and collision baking techniques from the perspective of three sub-topics that exist in cross-platform game development, and test and examine them. Finally, it summarizes the shortcomings in module design and implementation, and explores more efficient and less costly cross-platform game development strategies.
  ]
  #thesis-contents()
]

// 这里是正文
#mainbody[
  = 绪论 <CH1>

  == 研究背景及研究意义 <CHH1>
  近年来移动设备性能快速进步 @Adreno2025 @MaliProcessor2025，新一代设备在核心性能上已经大幅缩小同高性能 PC & Console 的差距。同时，Nintendo Switch 的不断热销和 Linux 游戏生态的改进，催生了输入方式、屏幕尺寸、硬件组合多样化的掌上游戏设备生态。2020 年以来，开发以“一次开发，多端部署，管线共用，内容一致”为鲜明特征的跨平台游戏成为行业主流趋势之一。

虚幻引擎的渲染管线、关卡流送等基建在行业中十分突出，在近年来落地许多前沿成果。2020 年对前向渲染管线提供现代化支持；2021 年率先交付软动态全局光照技术，并提供原生“一Actor一文件”流送能力；2023 年为全资产提供虚拟几何体支持，等等。

经历 3-4 年的研发周期后，2024年行业出现了一批高品质、涵盖多种主流品类的跨平台游戏。跨平台游戏开发需要大量前期投入和试错成本，近期基于虚幻引擎开发并上线的跨平台游戏几乎全部为数百人团队、5亿成本之上的大型游戏。它们的开发过程中积累了许多宝贵经验，贡献了许多可供复现和整合的思路。在这个时间点，小型开发者通过借鉴这些经验和思路，开发出更高品质跨平台游戏已经成为可能。

据此开展的一系列研究，面向跨平台渲染管线、新一代输入处理工具和资产及碰撞烘焙技术三个跨平台游戏开发堵点，综合集成并改进技术方案，并量化评估其改进成果和现实意义。
  == 国内外研究现状 <CHH2>
  现代渲染管线的研究经历了约30年历程。在介绍具体的电子游戏工业界研究之前，有必要先简述相关渲染技术的重要研究节点。

前向渲染（即Forward Rendering）概念由来已久，与早期图形管线的发展紧密相关。Nvidia在1999年推出了首款现代GPU，标志着前向渲染过渡到可编程管线 @cookReyesImageRendering。

传统延迟渲染（Deferred Rendering）可追溯到1990年。Saito和Takahashi最早提出了延迟着色（即Deferred Shading）的概念 @saitoComprehensibleRenderingof3DShapes1990。 2004年，Rich Geldreich和Matt Pritchard在当年的游戏开发者大会（Game Developer Conference，后称GDC）上正式提出了延迟渲染概念：先执行深度测试，再进行着色计算，将本来在三维空间进行光照计算放到了二维空间进行处理。延迟渲染的概念中，先将所有物体都先绘制到屏幕空间的缓冲（即G-buffer，Geometric Buffer，几何缓冲区，对应显示硬件的特定区域）中。之后，逐个按光源对物体进行遍历，完成着色。计算被深度测试丢弃的⽚元（像素）的着色在传统前向渲染管线中会产生不必要的开销，延迟渲染将能够避免这一点 @shawnhargreavesDeferredShading。

Lauritzen, Andrew在2010年对延迟渲染管线进行了进一步展望，引入了Tiled-Based延迟渲染等概念 @lauritzenDeferredRenderingCurrent。

延迟渲染管线表现优异，但由于G-buffer对显存容量和带宽要求较高，它对移动端支持不佳。随着iPhone和App Store的推出，21世纪10年代移动端游戏市场规模快速发展 @zouNEWYORKUNIVERSITY2024，移动游戏开发成为一个课题。

2012年，Harada等人的研究介绍了拓展前向渲染管线（即Forward+，有时也成为“现代前向渲染管线”；本文中如无特别指出，均用“前向渲染管线”或“Forward+”简称“拓展前向渲染管线”）@harada25DCullingForward2012，它是对传统前向渲染管线的拓展，可视为一种通过光照剔除和仅存储对像素有贡献的光源来渲染许多光源的方法。具言之，Forward+拓展了一个光照剔除Pass，用以响应对高效多光源渲染的需求。作为前向渲染流程的拓展，它还可避免渲染庞大的G-buffer，十分节省内存和显存。Takahiro Harada, Jay McKee, 和Jason C.Yang的研究对Forward+渲染管线和传统延迟渲染管线的性能进行了量化比较 @haradaForwardBringingDeferred2012 @DeferredShadingOptimizations2011。

虚拟几何体、软动态全局光照和MegaLight等技术可追溯至5-7年内。Chris Wyman等人在研究中提出了ReGIR采样算法，对光源的重要性进行采样，大大拓展了场景中动态灯光数量上限；
Daqi Lin，Cem Yuksel和Chris Wyman在后来的工作又将原基于屏幕空间的算法扩展到体积介质的多维路径空间，实现了低噪声、交互式的体积路径追踪 @linFastVolumeRendering2021。

Brian Karis，Rune Stubbe，Graham Wihlidal等人提出了在虚拟纹理系统基础上创新的填充方案，在光栅化流程之前剔除高精度资产等三角面，允许用户将超高精度的资产整合到场景中；这一研究为工业界的“虚拟多边形”技术奠定了基础 @briankarisNaniteDeepDive2021。

Daniel Wright、Krzysztof Narkowicz、Patrick Kelly等人的研究将动态间接光照工程化，并直接推动了软动态全局光照在游戏引擎中的实现 @danielwrightkrzysztofnarkowiczpatrickkellyLumenRealtimeGlobal2022。这些工作解放了预烘焙光照的许多局限。这些技术为下面工业界的实践奠定了基础。

国内工业界在跨平台游戏技术研究方面走在前列。2024 年，Shangli Liang 和 Yang Shi 介绍了一种利用虚幻引擎延迟管线，涵盖资产生产、运行时处理等多方面内容，以实现高效利用和跨平台适配的资产生产、合并、剔除策略和技术 @liangDeltaForceTechniques。报告内容中提及，《三角洲行动》团队采用LOD链管理细节层次，将碰撞网格与物体网格分离，在高性能平台和低性能平台保证一致的游戏性内容。同时，开发了专门的外部工具 Jade Hub 用以指定资产平台和设置资产层级，在导入环节对资产进行验证，通过 JSON 文件传递资产路径、材质模板等关键信息。

Tieyi Zhang 介绍了一种通过定制虚幻引擎的默认延迟管线来实现“奇异博士”传送门的技术 @tieyizhangAdvancedGraphicsSummit。开放式传送门通常会使渲染工作量翻倍，这给性能带来了挑战。报告中提供 CPU 和 GPU 优化的高级概述，以及用于将传送门调整为其他英雄技能的许多策略。 最终，《漫威争锋》玩家将体验到逼真、可自由放置和交互式的传送门。这些传送门在保持相对较高帧率的同时，还能让玩家看到对面的情况。该解决方案可以在另一侧显示实时场景，允许角色、子弹和其他物体无缝通过，而不会妨碍玩家的主视图。

Shaoyong "Abel" Zhang 从移动游戏视觉特效艺术家的角度，对 14 种着色器进行数学分析。最终，他提出了一种在设计之初就能保证移动端兼容性，保证表现并提高性能的策略。

国外工业界在跨平台游戏开发方面的研究在今3-5年同样取得许多成果。Kosuke Tanaka和Takashi Komada介绍了一种对中型开发者来说稳健和具备高品质效果的风格化视觉效果实现路径 @gameworksToonRenderingHiFi。这一报告对本文所着重对小型开发者尤为关键，它介绍了在不修改引擎的前提下，完全利用虚幻引擎的渲染管线进行定制化光照开发的技术，以及利用延迟管线制作全局光照的许多实践@gameworksToonRenderingHiFi。

以上是国内外业界通过对虚幻引擎渲染管线的发掘和改进进行的跨平台游戏开发研究实践。新一批跨平台游戏开发技术将拓展中小型游戏开发者的工程能力，允许其制作更大规模、更高品质、具更强竞争实力的产品；工业界正在尝试落地包括但不限以上列出的新一代技术。当前技术门槛和试错成本较高，我们可以观察到行业正处于大型团队初步交付、中型团队落地开发、小型开发者借鉴跟进的阶段。已初步具备进行相应研究和探索的条件。
  == 研究内容及章节安排 <CHH2>
  本研究立足跨平台游戏开发技术。主体上，基于小团队视角，复现、探索和集成跨平台渲染管线在Toon Shading，定制化室内光源（阴影）、SSAO和全局光照方面的应用、新一代输入处理工具及资产及碰撞烘焙技术。之后通过Unreal Insight等性能测试工具，对整体解决方案进行定量评估。

本文的章节安排如下：

第一章，绪论。介绍了研究背景与意义，然后对跨平台游戏开发的基本原理和国内外研究现状进行介绍，最后陈述本文研究内容和计划。

第二章，跨平台游戏开发原理。在绪论基础上，介绍与本文工作相关的模块、算法、三种渲染管线和全局光照等技术的原理与特征，并列举一些工业界实践中的具体成果。

第三章，基于虚幻引擎的工程设计。本章节详述工程中使用的虚幻引擎功能以及三个模块的具体设计。

第四章，测试、评估和讨论。首先介绍性能评估技术和流程，并展示性能评估结果和（不涉及性能部分模块的）实际效果展示。

第五章，结论。总结全文，分析研究取得的成果和存在的不足之处，并讨论未来可能的工作方向。
  = 基本概念和技术 <CH1>
  == 跨平台渲染管线背景信息
  跨平台游戏指在多个平台（如个人电脑、手机、游戏主机）上具备相同内容和游玩体验的游戏。本节中介绍与跨平台渲染管线相关的概念和技术。
  === GPU着色器
  GPU着色器是GPU中完全可编程的模块。GPU渲染管线是更宏观的渲染管线之一部分。图形渲染管线即在给定虚拟相机、三维物体、光源、照明模式和纹理等条件下，生成对应二维图像的过程，分为应用程序阶段、几何阶段和光栅化阶段。

1987年，Cook最先提出了可编程着色的思想。1999年Nvidia 发布了首个包含定点处理功能的图形芯片，并将其命名为GPU。该芯片可以处理顶点着色器、几何着色器、CLipping、屏幕映射这些几何阶段的运算，亦能处理光栅化阶段中包括像素着色器的多种算法。GPU提供了对顶点着色器（Vertex Shader)、几何着色器（Geometry Shader）和像素着色器(Pixel Shader)的可编程支持。现代着色阶段中，三套着色器共享同一套编程模型，使用类如HLSL和GLSL一类的着色器语言，下文中会使用它们。

顶点着色器在三个着色器中位于最靠前的阶段。它可以在现代CPU或GPU中执行。2001年，DirectX 8中首先引入这一概念；如今，现代OpenGL、Vulkan和Metal仍在使用。顶点着色器可对创建、修改或变换顶点。这里的“修改”有专门强调的价值：多边形顶点的参数包括位置、颜色、法线、纹理坐标，等等。顶点着色器会输出顶点空间变换后（一般是齐次裁剪空间）的坐标。顶点着色器输出的数据可在光栅化过程后发送给像素着色器，也可发送给几何着色器，或二者兼有。

几何着色器位于顶点着色器和像素着色器之间，接收图元输入。它只能输出点、折线或三角形条。后文使用的部分虚幻引擎基建大量设计使用了几何着色器，但本文中不会直接使用它，而是通过已有基建进行几何变换。

像素着色器在现代图形API中也称为片元着色器（Fragment Shader），对每个顶点执行着色方程，输出顶点的颜色。它的输入实际上是顶点着色器的输出。严谨地讲，前文的“发送”实际上是像素着色器内部流程的一部分。光栅化如Clipping、屏幕映射、三角形设定的许多步骤在像素着色器内部完成。

在像素着色器之后（有些时候是像素着色器的最后），进行合并操作。合并阶段中，进行模板缓冲（即Stencil-Buffer）和Z缓冲（也就是Z-Buffer）。虚幻引擎渲染管线中将这部分数据暴露给用户，允许其对顶点数据进行涉及RGBA（也就是颜色和Alpha值）的加减乘和其它位运算，下文中我们将利用这一点。
=== 透明排序算法
虚幻引擎通过深度缓存算法实现透明排序。首先介绍这个算法。

在渲染开始前，将深度缓存中的所有像素值初始化为一个极大值（表示无限远）或一个特定值（取决于深度范围定义）。同时，初始化颜色缓冲为背景色。

然后逐个渲染场景中的图元（如三角形）。对于每个图元覆盖的像素，首先计算该像素对应的三维空间点的深度值（Z值）。这个深度值将会与深度缓冲中对应像素位置存储的深度值进行比较。 如果新计算的深度值比缓存中的值更小，表示该顶点更靠近观察者；更新深度缓存中该像素的深度值为新的、更近的深度值。当然，也要更新颜色缓存中该像素的颜色为当前图元的颜色。如果新计算的深度值不小于缓存中的值，则表示该像素已被更近的物体遮挡，丢弃当前图元的这个像素信息，不更新任何缓存。

当所有图元都处理完毕后，颜色缓存中存储的就已经是最终可见表面的图像。这一算法显然无法对半透明物体进行排序。后文中会提及延迟渲染管线和前向渲染管线的分别，但在这里已经可以首先论述：半透明物体的数据存在G-buffer等之中，属于延迟渲染管线。因此，在具体的工程实践中，笔者尽力使用前向渲染管线功能来达成跨平台支持，非常谨慎地规划所有与半透明相关的功能。

虚幻引擎首先对所有物体进行渲染，填充数据到G-buffer和深度缓冲之中。另外，虚幻引擎引入了一个单独通道（半透明）来处理半透明物体的排序。如前文所述，它还为用户提供了一个单独的缓冲（称为Custom Stencil），允许用户从模板缓冲中获取数据，或用自定义数据覆盖之。
=== BRDF模型
双向反射分布函数（Bidirectional Reflectance Distribution Function，下文称BRDF）模型在绝大多数图形算法中都得到采用。它用于描述光反射现象，即入射光线经过某个表面反射后在出射方向上的分布模式。BRDF中的几个变量使用一些辐射度量学单位。下面的公式中会用到：
辐射通量（Radiant Flux，又译作光通量，辐射功率）描述的是在单位时间穿过截面的光能，或每单位时间的辐射能量，通常用Φ来表示，单位是W，瓦特。
  $
    phi = frac(d Q, d t)
  $<32>
@32 中的Q表示辐射能(Radiant energy)，单位是J，焦耳。

对一个点（比如说点光源）来说，辐射强度表示每单位立体角的辐射通量，用符号I表示。
  辐射强度的公式为

  $
    
I = d Phi d omega I = (d Phi)/(d omega)
  $<34>

  辐射率（Radiance，又译作光亮度，用符号L表示）,表示物体表面沿某一方向的明亮程度，它等于每单位投影面积和单位立体角上的辐射通量，单位是瓦特每球面度每平方米。辐射率的微分形式：
  $
    L = d 2 Phi d A c o s theta d omega L = (d^2 Phi)/(d A c o s theta d omega)
  $<radience>
  @radience 中Φ是辐射通量，单位瓦特（W）；Ω是立体角，单位球面度（sr）。
  辐照度（Irradiance，又译作辉度，辐射照度，用符号E表示），指入射表面的辐射通量，即单位时间内到达单位面积的辐射通量，或到达单位面积的辐射通量，也就是辐射通量对于面积的密度。用符号E表示，单位为瓦特每平方米。辐照度可以写成辐射率（Radiance）在入射光所形成的半球上的积分：
  $
    E = integral_Omega^() L(omega) c o s theta d omega
  $<irradiance>
  @irradiance 中，Ω是入射光所形成的半球。L(ω)是沿ω方向的光亮度。

  BRDF从出射角度出发，描述入射方向和出射方向能量的关系。对反射表面进行积分后，以出射辐射率的微分与入射辐照度的微分作比，便得到BRDF方程的微分形式：
  $
    f(l, v) = d L o(v) d E(l) f(l, v) = (d L_o (v))/(d E(l))
  $<brdf1>
  这些描述是为了推导着色方程。在工程中，更多使用对BRDF着色方程的某种拟合。下面列出原始着色方程为：
  $
    L_o (v) = sum_(k = 1)^n f(l_k, v) times.circle E_(L_k) c o s theta_(i_k)
  $<brdf2>
  @brdf2 中，n是入射光的数量，f(l, v)是BRDF，E(l)是入射光的辐照度，v是观察方向，l是入射光方向。k是每个入射光的索引。

  虚幻引擎采用基于物理的BRDF模型。由Cook和Torrance提出，Cook-Torrance BDDF模型是最早的基于物理的BRDF模型 @cookReflectanceModelComputer1982。它将菲涅尔反射引入到着色模型之中 @UsingFresnelYour，定义为：
  $
    f(l, v) = (F(l, h) G(l, v, h) D(h))/(4(n dot.op h)(n dot.op v))
  $<cook-torrance>
  @cook-torrance 中， F为菲涅尔反射函数( Fresnel 函数 )；G为阴影遮罩函数（Geometry Factor，几何因子），即未被shadow或mask的比例；D为法线分布函数(NDF)。

== 三种着色管线
基于光栅化的渲染技术其计算效率高，在对帧率有严苛要求的交互式应用（如电子游戏、虚拟现实和实时模拟）中占据主导地位。二十年来，图形硬件性能快速提升，应用场景对视觉真实感的需求也在日益增长。光栅化着色管线在这一过程中经历了显著演进。本节中，重点阐述三种具有代表性的渲染管线技术：前向着色（Forward Shading，也称Forward Rendering，下同）、延迟渲染（Deferred Rendering）以及拓展前向渲染（Forward+ Rendering），对其核心原理、发展脉络及关键研究突破剖析之。

这里的着色管线也称为“渲染管线”，它们是运行在GPU渲染管线上具体的渲染技术。特别指出，前文提及的渲染管线是一个抽象的概念流程，与此有别，见图2.2。为避免与前文混淆，在标题中使用“着色管线”替代之。后文中如无特别声明，笔者都使用更加通行的说法“xx渲染管线”指代着色管线。


  #figure(
    image("image/渲染概念之间的关系.png", width: 5cm),
    caption: [渲染概念之间的关系],
    placement: none
  )
=== 前向渲染管线
前向渲染是最为经典且直观的渲染范式。在此管线中，每个几何图元（通常是三角形）独立地经过顶点处理、几何处理（可选）、光栅化和片段处理等阶段，得到最终图片。核心的光照计算发生在像素着色器中，针对每个通过深度测试和模板测试的像素（潜在的片元），根据其材质属性、表面法线、视角方向以及场景中的相关光源信息，直接计算最终颜色值。

前向渲染的早期形态与固定功能图形硬件紧密相关。此时，光照计算模型相对简单且在硬件中以硬编码存储。20世纪90年代中后期可编程着色器的引入允许用户在着色器中实现复杂的材质和光照模型。
前向渲染管线结构简单，对MSAA和透明物体的支持也更好。前向渲染管线中，光照计算复杂度通常与场景中的“对象数量 × 光源数量”成正比（即 O对象×光源）。当场景中存在大量动态光源时，渲染性能会急剧下降。此外，对于复杂场景，大量像素可能被后续渲染的物体遮挡，（这一现象称作过度绘制，Overdraw），在这些最终不可见的像素上浪费了大量的片段着色计算。传统前向渲染管线对许多现代图形特性的支持也十分有限。

=== 延迟渲染管线
延迟渲染管线将渲染过程解耦为两个主要阶段：几何Pass（Geometry Pass）和光照Pass（Lighting Pass）。在几何Pass中，场景中的不透明物体的几何信息（如世界坐标位置、法线、漫反射颜色、高光属性等）首先被渲染（“写入”）到一组屏幕空间的中间缓冲区中，这组缓冲区统称为几何缓冲区（Geometry Buffer, G-buffer）。在光照阶段，通过读取G-buffer中存储的逐像素信息，对屏幕上每一个可见的像素执行一次光照计算。这样，光照计算的复杂度与屏幕像素数量和光源影响范围相关，而与场景的几何复杂度（对象数量）基本解耦，显著提高了处理大量光源的效率，并从根本上避免了对被遮挡像素进行光照计算的浪费。用户还可以添加自定义Pass，为游戏增加多种风格化表现。延迟渲染管线也提供对半透明物体的支持。

延迟着色的概念雏形可以追溯到 Deering 等人 (1988) 以及 Saito 和 Takahashi (1990) 的研究工作，后者明确提出了G-buffer的概念。该技术在早期并未普及，直到图形硬件具备了足够的特性支持，特别是 Shader Model 3.0 于2004年引入的多渲染目标（即Multiple Render Targets, MRT）能力，才使得延迟渲染得以高效实现并逐渐成为主流。诸如《怪物史莱克》(2001) 和《杀戮地带2》(2007) 等游戏的早期实践和演示推动了延迟渲染管线在业界的采纳。2010年前后，出现了基于瓦片的延迟渲染（Tile-Based Deferred Rendering，下文称TBDR）由于G-buffer的读写操作十分频繁且会随着着色器和自定义Pass规模膨胀而大幅上升，延迟渲染会带来较高的内存带宽消耗，这让许多面向延迟渲染管线开发的图形特性难以适配到低性能平台上。
=== 拓展前向渲染管线（Forward+）
拓展前向渲染是一种旨在结合前向渲染和延迟渲染优点的混合渲染技术。它本质上仍是前向渲染流程，保留了对透明度和MSAA的良好支持。其核心创新在于引入了一个高效的光照剔除（Light Culling）预处理阶段。在该阶段，通常利用计算着色器（Compute Shader），将屏幕空间划分为二维的“平铺”（Tiles）或者进一步考虑深度信息划分为三维的“聚类”（Clusters）。然后，针对每个Tile或Cluster，快速构建一个仅包含对其产生影响的光源列表。在后续的（传统）前向渲染着色阶段，每个片段着色器仅需从其所属Tile/Cluster的光源列表中读取光源信息并进行计算，从而将需要处理的光源数量大幅减少，使其能够高效应对大量光源的场景。

该技术的相关思想（如平铺着色）大约在2011年由 Olsson 和 Assarsson 等人提出。Harada 等人 在2012年 正式提出了 Forward+ 的概念并进行了详细阐述。虽然它增加了光照剔除阶段的实现复杂度，但相较于需要为透明度和MSAA添加复杂变通方案的延迟渲染系统，其整体架构可能更为统一和简洁，且通常内存带宽压力更小。由于其在性能、效果兼容性和实现复杂度之间的良好平衡，Forward+及其变体（如Clustered Forward）已成为现代跨平台游戏和高性能渲染引擎的重要选择。

2017年，虚幻引擎添加对Forward+的支持。2023年，虚幻引擎移动端Forward+管线迎来重大改进。

= 基于虚幻引擎的功能设计
虚幻引擎发布于1998年，最早用于支持Epic Games的游戏《虚幻竞技场》，逐渐发展成为商业引擎。如今，虚幻引擎已成为跨平台游戏开发的主流选择。当前最新版本为虚幻引擎5.5。

本项目主要使用虚幻引擎渲染管线、增强输入系统和碰撞系统方面的基建，在其基础上作定制化开发。3.1节分析跨平台游戏开发面临的技术问题并划分切片，3.2至3.4节分别介绍弹性美术管线、输入与控制系统和碰撞生成等外围模块的设计和实现细节。
== 跨平台技术框架概述
=== 目标平台差异性分析
在利用虚幻引擎进行跨平台游戏开发时，深入理解目标平台间的固有差异性是构建稳健且高效技术框架的基石。本段涵盖GPU、内存子系统特性、屏幕规格以及用户输入方式等多个维度，它们直接影响用户体验和开发策略。
1. 图形处理性能与特性支持存在显著差异
不同平台间，GPU计算能力具量级上的差距。以浮点运算性能（FLOPS）为例，高端PC平台的GPU（如Nvidia RTX 4090）可达到数十TFLOPS ，主流游戏主机（下文称Console，如PlayStation 5和Xbox Series X）则在10-12 TFLOPS这一量级。作为对照，移动平台的GPU性能跨度极大，从几GFLOPS到数TFLOPS不等，即使是高端移动GPU（如高通Adreno X1-85或苹果M系列GPU）其峰值性能也与主机和PC存在显著差距；尽管其发展迅速，已能超越部分老旧主机。

巨大的性能鸿沟直接决定了不同平台上图形特性的支持程度和实现复杂度。高端PC和Console藉由强大的GPU算力和更大的显存带宽（PC可达1 TB/s以上，Console约400-560 GB/s） ，能够支持如实时光线追踪、高分辨率纹理、复杂Pass结构和着色器模型以及高密度几何体渲染等尖端图形技术。移动平台GPU性能和内存带宽（通常在几十至数百GB/s范围） 相对有限，往往需要依赖TBDR  和纹理压缩技术（如ASTC）来缓解带宽压力 [Source 1]。移动游戏往往在特性支持上有所取舍，一些方案包括简化光照模型、降低多边形规模或采用屏幕空间技术的近似实现。
操作系统（Windows, macOS, Android, iOS）及其对应的图形API（DirectX, Metal, Vulkan, OpenGL ES）间在功能集、驱动效率和底层硬件访问权限上亦有区别 。在虚幻引擎提供了渲染抽象层来屏蔽部分底层差异的情况下，开发者仍需考虑降级图形特性，在构筑图形方案时考虑共用能力。
2. 屏幕尺寸、分辨率与输入方式的多样性
移动设备市场存在大量不同的屏幕尺寸、分辨率（从低于HD到超过QHD）和像素密度（DPI范围从300到500+ PPI） ，高度碎片化。Console通常面向客厅电视或显示器，目标分辨率较为固定。 。PC平台介于两者之间，1080p（1920x1080）仍是主流，但1440p和4K分辨率的普及率快速增长，且支持包括超宽屏在内的各种宽高比。

平台间输入方式多样。如简单的位移操作，在键盘上对应4个按键的布尔值，在控制器中对应一个二维浮点数。也就是说，无法简单地通过替换映射来达成跨平台适配。
=== 技术切片划分
基于上述情况，功能设计分为三个模块：弹性风格化美术管线、输入处理中间件和碰撞管理功能。在这里，笔者简述模块设计思路；下文将介绍其具体实现。

美术管线在这里指代图形特性的选型、制作和部署。承接前文，所有具体实践服务于三个目标：共用基座——核心流程一致；表现可伸缩——部分特性具备高端化能力；不修改引擎——小型团队跨平台开发的客观需求[hifi]。虚幻引擎也使用“PC端渲染管线”和“移动端渲染管线”的提法。作为基建，这两条管线中是延迟管线和拓展前线管线之具体特性按不同方式组合而成的。下文中使用“某某特性从属于某某渲染管线”这样的提法时，如无特别指出，一般不指代虚幻引擎面向用户提供的“渲染管线”概念，而是更加通用的“某某特性具备延迟管线（前向管线）的特征”。管线部分大致划分如下：

1. 一般核心特性。二分Toon Shading和自定义灯光在拓展前向管线中完成。非天光阴影和SSAO正常产生投影使用自行开发的排线和网点效果。描边效果在延迟管线中完成，仅添加1个Pass。
2. 后处理特性。高光溢出效果和Bloom基于虚幻基建作简单调整。在G-Buffer中，存储了自定义Stencil用以遮挡剔除。
3. 全局光照。在虚幻引擎的基础上实现；使用Lightmass重要性体积，只在想要的区域烘焙Lightmass Map。预设项目是恒定侧边视角，在高端平台上启用该机制。

输入处理系统。虚幻引擎现有的输入基建为UEnhancedInput，较为完备地考虑了通用场景。本文中，基于Gameplay Ability System（后称GAS）拓展了输入处理能力，将输入操作直接暴露给游戏逻辑，简化了跨平台输入修饰工作。材质函数包含以下几个区别于普通材质节点的节点：
虚幻引擎的输入基建如图3.1。
  #figure(
    image("image/uenhancedinputcomponent_structure_cn 1.png"),
    caption: [UEnhancedInputComponent结构图],
    placement: none
  )
碰撞管理功能。不同平台所使用的资产精度有所分别。为实现碰撞与几何的解耦，使用Pocedural Mesh构建了通用碰撞机制。

=== 预设项目背景

虽然本研究不涉及交付完整、可玩的游戏本身，但有必要预设一些项目背景。只有在本段限定的游戏类型之内，下文中所描述的特性才能正确工作。

本研究的意义在于探索小型团队可复制的跨平台游戏开发技术。类《银河战士》是小型团队近年来投入开发的主流品类之一@datainteloMetroidvaniaGamesMarket。下文的技术选型也以该类型游戏开发为背景，打造卡通风格化画面表现。
== 风格化弹性美术管线实现
=== 美术管线核心特性设计
整体来说，在虚幻引擎渲染管线的基础上进行定制。使用的工具以材质蓝图（Material Blueprint）为主。一部分逻辑使用BP编写，也有许多特性使用HLSL这类着色器语言。虚幻引擎提供了Custom节点，由此可将自定义着色器封装到整体管线中。

 主光照构建策略。基本的Toon Shading在拓展前向管线中完成。Toon Shading的核心目的是明亮、锐利和快速；作为最核心的基本表现，也需要做到完全共用。主光照的目的为使物体产生自阴影（亮暗面）。亮面与暗面之间有明确分界线，且暗部会被指定一个特定颜色。最终，决定使用唯一天光照亮整个场景。所有物体并不直接响应天光，而是基于其方向生成明暗二分。另外，暴露了暗部颜色和过渡级数给材质实例，支持人工干涉最终色彩表现。材质效果、组件面板见图3.2、图3.3。
  #figure(
    image("image/主光照材质效果.png", width: 5cm),
    caption: [主光照材质效果],
    placement: none
  )
    #figure(
    image("image/主光照组件面板.png", width: 14cm),
    caption: [主光照组件面板],
    placement: none
  )

场景光照构建策略。项目中同时存在3D模型和2D Sprite，需要分别制作符合资产特性的灯光。Unreal 自带灯光在延迟管线和前向管线上表现差异较大，且容易生成伪影和噪点。因此，本研究中笔者在前向管线上自定义 3D 灯光。虚幻引擎拥有较为成熟的贴花技术，由于风格化场景不追求物理精确的光照强度衰减，使用其作为自定义光源非常合适。材质设计见图3.4，光照组件蓝图设计见图3.5。
  #figure(
    image("image/decalLight.png", width: 14cm),
    caption: [贴花光源设计],
    placement: none
  )
  #figure(
    image("image/BP_decalLight.png", width: 14cm),
    caption: [光照组件蓝图设计],
    placement: none
  )

灯光被封装为一个单独蓝图Actor，以世界位置为中心，向一定半径内的物体表面投射光照。为了改善表现，制作了多种类似现实中异形镜头光圈的Mask进行投射。可以通过搭配这些灯光，丰富场景视觉效果。另外，制作了剔除Box，可将光照在场景中“截断”：既可以让用户灵活定制光照表现，亦具防止光照渗透到物体背面之用。

2D灯光需要解决默认情况下3D灯光照亮Sprite边缘，“纸片感”强烈的问题。为解决这个问题，在延迟管线中自定义光照性质。按距离的平方而非距离衰减，过渡会更自然。2D灯光响应Sprite法线。理论来说，人工绘制法线效果最优；但从工程角度，这不现实。最终，在Sprite材质中增加特性：使用边缘检测算法自动生成边缘法线。
=== 周边特性
接下来介绍风格化高光/阴影、环境光遮蔽等技术相关细节。

具言之，在前向管线中构建半色调网点纹理，再将其投射至场景中。Bloom效果由半色调网点填充，阴影和环境光遮蔽由排线填充。项目中没有使用图片纹理，而是完全由GPU驱动，程序化生成纹理以节省内存。使用HLSL编写着色器生成两类纹理：网点和排线。效果图见图3.6、图3.7。基于有向距离场生成纹理。通过期望纹理坐标、点的颜色、背景颜色、点的半径就可以绘制出一个点。制作排线时，将Y轴的UV赋0。网点和填充线的尺寸、密度、颜色均暴露给材质实例调节。

`
float2 ScaledUV = UV * Freq;
float2 FracUV = 2.0 * frac(ScaledUV) - 1.0;
FracUV.y = 0.0; 
float Dist = length(FracUV);
float SmoothWidth = 0.02; 


float Alpha = smoothstep(Radius - SmoothWidth, Radius + SmoothWidth, Dist);
return lerp(LinesColor, BGColor, Alpha);
}
`
  #figure(
    image("image/hLine.png", width: 5cm),
    caption: [着色器生成的排线],
    placement: none
  )

    #figure(
    image("image/tone.png", width: 5cm),
    caption: [着色器生成的网点],
    placement: none
  )

后续，使用三平面投射算法将其混合到几何体表面。Bloom效果混合半色调网点，阴影混合排线。在有些场景中，可能需要根据实际表现对场景进行暗部调节。项目中使用与上文类似的技术制作了贴花阴影，可满足相关需求。Bloom区域在延迟管线中生成，存储在G-Buffer中。这一数据仅用于后续基于屏幕空间的纹理混合。在强度控制上，笔者使用虚幻引擎自带的Bloom算法。额外添加的网点混合已经能够带来相对完备的视觉表现。

在类《密特罗德》类型的电子游戏中，常常要处理物体遮挡关系判定。传统的判定方式是射线检测等；在这里提出使用深度通道进行编码的检测方式。用户可以访问虚幻引擎渲染管线中的Z-Buffer，或用自定义深度（Custom Stencil）按Actor覆盖之。自定义深度使用8位二进制编码。之后，添加一个自定义Mask，对像素的深度数据按位运算。简单对比最终结果，即可得知物体遮挡关系。见图3.8。

    #figure(
    image("image/stencil.png", width: 10cm),
    caption: [自定义深度检测],
    placement: none
  )

== 输入与控制系统开发
=== 控制层基础设施
从操作系统和硬件驱动接收信号这一步骤由虚幻引擎基建UEnhancedInput实现。本项目中，相关模块的开发情况如下：图3.9描述了一个角色控制器的上下游资源。
#figure(
  image("image/Pasted image 20250430132107.png",width: 10cm),
  caption: [角色控制器上下游资源],
  placement: none
)

从Character类继承，创建了自定义Character类GAS_Character。GAS_Character类的所有基本功能（包括移动和输入）都绑定到GameplayAbility，供下面的集成调用。添加的C++类如：
``` 
public:
	AGAS_PaperCharacter();

	/** ability system */
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = Abilities, meta = (AllowPrivateAccess = "true"))
	class UAbilitySystemComponent* AbilitySystem;
	UAbilitySystemComponent* GetAbilitySystemComponent() const
	{
		return AbilitySystem;
	};
	/** ability list */
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Abilities)
	TArray<TSubclassOf<class UGameplayAbility>> AbilityList;

	/** BeginPlay, PossessedBy override */
	virtual void BeginPlay() override;
	virtual void PossessedBy(AController* NewController) override;
};

```
在GAS_Character类的基础上，得到蓝图类PlayerBase。从头设计其中的组件。使用组合的设计思想，纳入一系列与输入控制、碰撞和响应的组件。
=== GAS 集成
将输入系统同GAS集成在工程上有一系列好处。通过添加一个抽象中间层，项目得以将输入处理逻辑和游戏角色逻辑解耦，并能方便地通过输入直接触发游戏逻辑（或通过输入数据本身进行游戏逻辑判定）。项目引入了第三方中间件NinjaInput作为GAS集成的基础。笔者的工作主要集中于将该中间件集成到项目的角色控制系统中，之后根据项目需求进行配置：将输入操作映射到移动、交互等具体能力，以验证跨平台输入支持方面的可行性。中间件及虚幻引擎相关基建的组件和具体绑定模式见表3.1。表格中大部分组件都没有开头的字母U，是因为虚幻引擎用“U+组件名”的方式命名组件所属的C++类。本项目中大多数逻辑在BP中完成，添加的C++文件仅仅起到定义作用。中间件自身的工作流程见图3.10。

#figure(
  table(
  columns: (auto, auto, auto, auto, auto),
  inset: 10pt,
  align: auto,
  table.header(
    [*组件*], [*所属系统*], [*主要职责*],[*与Enhanced Input交互*],[*与GAS交互*]
  ),
  [UEnhancedInputComponent],[材质响应天光+GI],[材质响应天光],[],[],
  [材质二分],[动态],[仅户外动态],[],[],
  [风格化阴影],[投影+SSAO],[静态阴影],[],[],
  [光照],[动态光源+贴花光源],[贴花光源],[],[],
  [描边],[后处理中完成],[基于物体材质],[],[],
  [调色],[后处理中完成],[无],[],[],
  [模型精度],[LOD 0/LOD 1/LOD 2],[LOD 2/LOD 3],[],[],
  [纹理分辨率],[2K/4K],[1080P/2K],[],[],


),
  caption: [弹性部署中的表现降级细节],
  placement: none,
)

这页删掉
#pagebreak(
  to: "even"
)


#figure(
  image("image/ninja_input_workflow.jpg", width: 18cm),
  caption: [中间件Ninja Input工作流程],
  placement: none
)

具体而言，笔者访问UNinjaInputHandler，并在其中拿到来自UEnhancedInput组件的输入信息UInputAction。中间件允许开发者在InputHandler中注入自己的逻辑。在本项目中，由于GameplayAbilityComponent在GAS_Character类中已经激活，笔者可直接通过蓝图将其绑定到自行设计的GameplayTags上。等效C++伪代码为：

`
void UInputHandler_SampleActivation::
HandleTriggeredEvent_Implementation(UNinjaInputManagerComponent* Manager, const FInputActionValue& Value, const UInputAction* InputAction, float ElapsedTime) const { UAbilitySystemComponent* ASC = Manager->GetAbilitySystemComponent(); ASC->TryActivateAbilitiesByTag(AbilityTags, true); }
`

GameplayTags包括基本移动输入（Move和Jump），在项目设置中预置即可，此处不再赘言。之后，在InputHandler组件中即可将Gameplay Event发送（对应上图中的Activate Ability）到BP_PlayerBase（也是Character）类中，只需要在对应接口中实现具体逻辑即可。也就是说，InputHandler向上接管抽象输入，自身提供对输入本身逻辑的处理空间，向下允许具体蓝图通过接口实现逻辑。只需要在InputHandler中制作对不同输入逻辑的支持，即可实现跨平台适配。

== 外围工程模块

=== 碰撞生成系统

碰撞生成系统的核心设计目的是：在几何体和碰撞解耦合的背景下，基于空间点的采样生成经过这些点的碰撞盒。虚幻引擎提供了DynamicMesh基建，赋予开发者在运行时建立、修改和烘焙碰撞的能力。本项目中将利用它。具体而言，碰撞系统包含两个模块BP_FrameManager和BP_CombinedBoundary。模块设计见图3.11。

#figure(
  image("image/Pasted image 20250501140038.png", width: 15cm),
  caption: [碰撞生成系统模块设计],
  placement: none
)

系统流程:
  + Geometry 包含多个 Anchor。
  + 宏收集 Anchors 成数组。
  + 调用 BP_FrameManager.RegisterFrame() 传入 Anchor 数据。
  + BP_FrameManager 处理 Anchors/Frames, 计算出 Segments。
  +  BP_FrameManager 调用 BP_CombinedBoundary.UpdateBoundaryShape() (传递 Segments)。
  + BP_CombinedBoundary 排列 Segments 并生成最终的碰撞网格。
笔者选用样条线作为生成Dynamic Mesh的几何数据。最终，这一系统产生简化和去重后的样条线，供相应函数生成和更新，见图3.11。

    #figure(
    image("image/Pasted image 20250501150418.png", width: 15cm),
    caption: [以样条线形式存储边界形状],
    placement: none
  )

  除了图片描述的两个模块之外，还封装了BP_FrameGenComponent。任何Actor添加该组件后，都具备输出锚点和向BP_FrameManager注册的能力。万事俱备之后，在GenerateBoundaryMesh()中烘焙为StaticMesh。虚幻引擎的碰撞概念抽象为Object Channel和Trace Channel。碰撞盒自身占据一个Object Channel类型，其它类（如Character）会被Block；碰撞盒之间通过单独的TraceTV通道互相检测，用以在布尔运算之前对边界预先剔除。

  = 测试与评估
  对于较重要的功能，制作了测试场景来对照效果和量化性能。对于无法量化的部分（如视觉效果），侧重于模拟不同设备场景，比照表现差异；而对于可量化的部分（性能），使用原生方案作为对照，量化比照性能数据。
  == 图形性能测试
本节对第三章所述的渲染管线进行性能测试。测试分为基准性能测试和跨平台性能对比。基准性能测试将最终解决方案和Unreal默认管线性能进行对比，跨平台性能对比展示在高性能（PC&Console）/低性能平台（Mobile，Nintendo Switch）上的性能和表现差异。各项测试数据均在Unreal独立线程中使用Unreal Insight抓取，并经过相关性检验。图4.1展示了测试对象和宏观指标，下文将展示这一过程。

#figure(
  image("image/unreal_lighting_test_overview.png", width: 16cm),
  caption: [测试对象和宏观指标],
  placement: none
)

=== 基准性能测试
本测试中模拟高端平台效果，对比同一场景在特性全开的弹性管线和虚幻引擎默认PC渲染管线的性能。在搭载AMD Ryzen 9 5900HX和NVIDIA GeForce RTX 3080 Laptop GPU的Windows计算机上进行测试。为模拟实际游戏运行效果，导入外部资产搭建了测试场景。测试场景自身参数见图4.2。
#figure(
  image("image/testscene.png", width: 15cm),
  caption: [测试场景和宏观参数],
  placement: none
)


对照组为同资产在虚幻引擎默认PC渲染管线下的性能参数。抓取了一段时间内性能参数（包括Frame Time、GPU Base Pass耗时（GPU Time）、Game线程耗时和RHIT），性能分析源日志见附录A。
剔除离散数据之后，整理的性能对比结果见表4.1。
#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: auto,
  table.header(
    [*指标（取平均值）*], [*项目管线*], [*默认管线*],
  ),
  [Frame Time(ms)],$16.67$,$22.09$,
  [GPU Time(ms)],$14.28$,$20.74$,
  [Draws(count)],$5073$,$5725$,
  [Game(ms)],$10.94$,$9.62$,
  [RHIT(ms)],$5.43$,$7.80$,
),
  caption: [管线间性能对比],
  placement: none,
)

着色复杂度对比见图4.3、图4.4。
#figure(
  image("image/shadingComplex1.png", width: 10cm),
  caption: [项目方案的着色复杂度],
  placement: none
)

#figure(
  image("image/shadingComplex2.png", width: 10cm),
  caption: [虚化引擎默认PC渲染管线方案的着色复杂度],
  placement: none
)
综上，可认为本项目的美术管线消耗的GPU和CPU资源普遍少于虚幻引擎默认PC渲染管线。
=== 跨平台性能对比
在高端（后称高端平台管线）与低端平台（后称移动管线）的弹性部署上，笔者没有做任何复杂的事情。有些高端特性（如GI和基于缓冲的屏幕空间后处理）原生不支持移动端，模拟时会直接剔除；资产流送参照虚幻引擎默认解决方案处理。唯一值得提及的是，由于资产本身没有任何阻止向下兼容的特性，直接将高端平台的低规格内容用于低端平台即可。降级细节见表4.2：
#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: auto,
  table.header(
    [*特性/资产精度*], [*高端平台管线表现*], [*移动管线表现*],
  ),
  [场景光照],[材质响应天光+GI],[材质响应天光],
  [材质二分],[动态],[仅户外动态],
  [风格化阴影],[投影+SSAO],[静态阴影],
  [光照],[动态光源+贴花光源],[贴花光源],
  [描边],[后处理中完成],[基于物体材质],
  [调色],[后处理中完成],[无],
  [模型精度],[LOD 0/LOD 1/LOD 2],[LOD 2/LOD 3],
  [纹理分辨率],[2K/4K],[1080P/2K],


),
  caption: [弹性部署中的表现降级细节],
  placement: none,
)


使用虚幻引擎的移动端模拟环境预览移动端效果。将图形API限制为Android OpenGL，使用独立线程完整模拟移动端表现。在移动端模拟器中使用与上一节类似的方式抓取性能数据，低端平台（此处为Android移动端）运行效果见图4.5，端间性能对比见表4.3。需要提前指出，帧生成时间等参数只有在基准硬件性能一致的情况下才有意义，因此有意未对性能做限制。不同的绘制用时能够反映平台间表现对应的性能需求差异。为展示跨管线性能差异，采集了ProfileGPU内部的更多参数。测试源日志见附录A。

#figure(
  image("image/testscenemobile.png", width: 15cm),
  caption: [测试场景在移动预览（独立线程模式）下的运行效果],
  placement: none
)

#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: auto,
  table.header(
    [*性能指标*], [*高端平台管线性能*], [*移动管线性能*],
  ),
  [Frame Time(ms)],$16.67$,$4.53$,
  [GPU Time(ms)],$14.28$,$3.18$,
  [Draws(count)],$5073$,$1127$,
  [Game(ms)],$10.94$,$2.93$,
  [RHIT(ms)],$5.43$,$4.20$,
  [ProfileGPU:BasePass(ms)],$0.57$,$0.62$,
  [ProfileGPU:ShadowDepths(ms)],$5.40$,$0.84$,
  [ProfileGPU:LightingAndTranslucency(ms)],$9.59$,$0.43$,
  [ProfileGPU:PostProcessing(ms)],$0.48$,$0.22$,
),
  caption: [端间性能对比],
  placement: none,
)
综上所述，这一美术管线总体达成了设计目的：在高低端平台上使光照和阴影等特性具备弹性表现的同时，最大化做到共用流程和资产。

== 外围模块测试
=== 输入模块测试
设计测试场景来比照不同输入设备（键鼠、游戏手柄、虚拟摇杆）的兼容性和输入延迟。

为此，设计了延迟测试类BP_LatencyLogger和接口BPI_LatencyTest。延迟测试类的功能是接收某次输入的绝对时间，并计算和统计与下一次输入被处理的绝对时间之差。使用Map记录不同操作产生的输入数据（下文样例中为Move），便于筛选和导出。任何实现了BPI_LatencyTest接口的Actor都可以被测试。操作时间将被输出到日志文件中。笔者在中间层IH_Move（承接虚幻引擎基建传来的原始数据）中实现该接口，这样测试数据仅针对中间件。重点比照不同输入手段两次处理之间的延迟。编写Python脚本对数据进行清晰、检验和对比。脚本见附录B。

使用Shapiro-Wilk检验评估数据正态性，使用Levene检验评估方差齐性。经过清理和检验的数据见表4.4，数据对比结果见表4.5。

#figure(
  table(
  columns: (auto, auto, auto),
  inset: 10pt,
  align: auto,
  table.header(
    [*指标*], [*手柄输入*], [*键盘输入*],
  ),
  "有效条目数",$1996$,$1667$,
  [平均延迟(ms)],$17.10$,$18.48$,
  [中位数延迟(ms)],$17.00$,$17.00$,
  [延迟标准差(ms)],$1.72$,$2.61$,
  [延迟最小值(ms)],$17.00$,$17.00$,
  [延迟最大值(ms)],$72.00$,$61.00$,
  [25百分位数(Q1, ms)],$17.00$,$17.00$,
  [75百分位数(Q3, ms)],$17.00$,$19.00$,
  [变异系数(CV, %)],$10.06$,$14.10$,


),
  caption: [手柄和键盘输入延迟对比],
  placement: none,
)

#figure(
  table(
  columns: (auto, auto, auto, auto),
  inset: 10pt,
  align: horizon,
  table.header(
    [*检验方法*], [*统计量/参数*],[*值*], [*p-value*],
  ),
  [独立样本t检验],$t$,$-18.488$,$<0.00001$,
  [Mann-Whitney U检验],[$U,|r|$],$\ U=962243.50,\ |r|=0.364$,$<0.00001$,
  [等效性检验],$Δ=0.3 \ms$,
  
  [$[-1.50 \ms$, $-1.26 \ms]$],"p_lower < 0.00001 p_upper < 0.00001"
),

  caption: [数据对比结果],
  placement: none,
)

就每组数据内部来说，两组数据的变异系数均较低，反映出模块能够稳定响应用户输入。

除此之外，仍需比较输入设备间的体验有何异同。可以看到，两种设备最典型的延迟表现（中位数）均为17.00ms，表示用户在多数情况下接受到的响应速度类似。键盘的平均延迟与手柄差值在统计上显著，因此可称两类输入设备在响应速度上存在约1.38ms的差异。即便如此，这一规模显著低于绝大多数用户的可察觉阈值@systemlatency。双单侧t检验的结果强力支持了这一点：因为90%置信区间完全落在预设的+—3ms等效边界内，所以有极高信心认为两组数据的平均延迟表现差异足够小，以至于在实践中完全可以忽略。

此外，日志还记录了输入处理栈。附录2可见到同一输入操作先后由键盘和游戏手柄触发，证实了该模块对热插拔的兼容性。



= 总结
== 工作内容总结
本文介绍了面向跨平台游戏开发的三方面课题所开发模块的设计思路和实现方法。核心内容包括：
1. 背景分析和技术切片分析；
2. 具体的模块分析；
3. 具体的模块实现；
4. 模块测试和展望。

在功能设计上，构建跨平台技术框架，针对目标平台差异划分技术切片，涵盖弹性风格化美术管线、输入处理中间件和碰撞管理功能；美术管线通过特定策略实现风格化效果与跨平台兼容，输入系统集成 GAS 提升处理能力，碰撞系统利用动态网格实现碰撞与几何体解耦。

== 不足之处和后续展望
=== 现有方案的不足
测试也反映出现有方案的缺陷。如：
1. 未能在Android设备上原生验证，仅借用虚拟化技术转译运行。
2. 对最新引擎特性的追赶和涉猎不足。虚幻引擎推出的一系列新技术（MegaLight、新材质系统、移动端VG）等都在不断对齐移动端对先进图形特性支持的上限，尽管还没有完全进入正式版，但已经对笔者的研究内容构成挑战。本文中部分结论的时效性可能有限。
3. 高端平台表现没有拉开明显差异。这一方面是时间、成本等因素让工业化项目更易追求表现上限的原因，另一方面也是笔者缺乏为项目从头制作美术资产能力所致。
4. 本研究使用的测试场景是为了突出特定的跨平台渲染特性对比而设计的。虽然涵盖了多种光照、材质和模型复杂度，但其规模和复杂度可能未能完全代表一个完整商业游戏项目的平均或峰值负载水平。

=== 未来展望
据此，接下来可以从三个方面改进：
1. 首要工作是克服Android打包和部署的技术障碍。这可能涉及：简化测试项目以定位具体问题、尝试使用不同版本的引擎或编译/打包工具链、更深入地学习Android NDK/SDK配置知识等。成功部署后，应在多种具有代表性的Android设备（覆盖低、中、高端不同性能层级和主流GPU供应商上，使用Unreal自带的工具（如Unreal Insights）和第三方工具（RenderDoc）进行全面的性能分析。获取并对比真实的帧率、CPU/GPU线程耗时、Draw Call/Triangle Count、内存占用峰值与均值、功耗以及温度数据，以验证和补充当前基于模拟的发现。
2. 拓展测试场景和复杂度，进一步评估在更高负载下的跨平台性能表现和瓶颈。使用或构建更接近商业游戏规模和复杂度的场景进行测试，包含更多动态元素、更复杂的AI行为、更丰富的粒子效果，等等。
3. 拓展项目规模，纳入更多新特性。积极尝试并验证虚幻引擎最新特性，构建规模更大、更具时效性的研究项目。

正如前文所述，跨平台游戏开发是
个复杂课题。个人研究如盲人摸象，本文所介绍的技术仅仅是游戏工业中的一个极小子集。全身心投入其中是与行业同频共振的最佳方式。未来，随着行业发展和项目经验积累，相信中国游戏行业将在包括但不限于跨平台游戏开发的领域中取得成果，走向更广阔的舞台。

]
// 这里是参考文献，致谢和附录
#after-matter[
  #bib("ref.bib")
  = 致谢
  敲下这几个字时，恰逢当日笼罩西安许久的热气散去，夜晚久违的通透。毕业设计能够有今日的完成度，离不开身边许多人的支持。

  首先感谢我的导师高悦老师。在选修计算机通信与网络这门课程的时候，我就被高老师的专业知识和严谨务实的学术态度深深感染，在毕业设计选题的时候，也第一时间联系了高老师，她的耐心和专业知识让我在完成项目的过程中受益匪浅。

  还要感谢我的家人。毕业设计的早期工作是在家中完成的，我的父母在这段时间的生活中给了我许多情感支持和生活上的帮助。

  此外，还要感谢一个特殊的群体，那就是西安电子科技大学的Nova独游社。在学校的紧张生活中，它提供了宝贵的的社交空间和做事氛围；我不仅在这里制作了自己的游戏，也结识了几位志同道合，一同前行的伙伴。

西安电子科技大学的校园也见证了我的校园生活。海棠食堂二楼吃了不知多少碗的米粉会成为我人生中难忘的回忆。

最后特别地，感谢毛星云——

你是我进入游戏行业的重要原因，也让我在2021年的冬日忽然决定放弃技术美术的道路。在做毕业设计的过程中，我拐回来第一次认真阅读你的技术博客系列。没有你知乎上翻译的RTR和极为详细的笔记/引用文献库，我不可能完成这一项目。真的很感谢你对这个世界所做出的贡献。

终于站在行业大门前的今天，我有期待，但更多是彷徨。是时候看向更长远的未来了；愿我们不会孤军奋战。


  #appendix[
    = 性能测试源数据
    == 高性能管线和性能分析日志
    这是由Unreal性能分析工具导出的高性能管线性能分析日志。
    ```csv
EVENTS,Exclusive/AllWorkers/RenderLighting,Exclusive/AllWorkers/UpdateGPUScene,Exclusive/AllWorkers/PrepareDistanceFieldScene,Exclusive/AllWorkers/RenderBasePass,Exclusive/AllWorkers/RenderPostProcessing,Exclusive/AllWorkers/SortLights,Exclusive/AllWorkers/ComputeLightGrid,Exclusive/AllWorkers/LightFunctionAtlasGeneration,Exclusive/AllWorkers/RenderCustomDepthPass,Exclusive/AllWorkers/Effects,Exclusive/AllWorkers/RenderPrePass,Exclusive/AllWorkers/RenderVelocities,Exclusive/AllWorkers/RenderTranslucency,Exclusive/AllWorkers/UploadDynamicPrimitiveShaderData,Exclusive/AllWorkers/Slate,Exclusive/AllWorkers/Physics,Scheduler/AllWorkers/SignalStandbyThread,LightCount/UpdatedShadowMaps,ShadowCacheUsageMB,Scheduler/Oversubscription,Exclusive/GameThread/Input,Exclusive/GameThread/TimerManager,Exclusive/GameThread/AsyncLoading,Exclusive/GameThread/EventWait,Exclusive/GameThread/WorldTickMisc,Exclusive/GameThread/Effects,Exclusive/GameThread/NetworkIncoming,NavigationBuildDetailed/GameThread/Navigation_RebuildDirtyAreas,NavigationBuildDetailed/GameThread/Navigation_TickAsyncBuild,NavigationBuildDetailed/GameThread/Navigation_CrowdManager,Exclusive/GameThread/NavigationBuild,Exclusive/GameThread/ResetAsyncTraceTickTime,Exclusive/GameThread/WorldPreActorTick,Exclusive/GameThread/QueueTicks,Exclusive/GameThread/TickActors,Exclusive/GameThread/Animation,Exclusive/GameThread/Physics,Exclusive/GameThread/EventWait/EndPhysics,Exclusive/GameThread/SyncBodies,Exclusive/GameThread/FlushLatentActions,Exclusive/GameThread/Tickables,Exclusive/GameThread/Landscape,Exclusive/GameThread/EnvQueryManager,Exclusive/GameThread/Camera,Exclusive/GameThread/RecordTickCountsToCSV,Exclusive/GameThread/RecordActorCountsToCSV,Exclusive/GameThread/EndOfFrameUpdates,Exclusive/GameThread/Audio,Exclusive/GameThread/DebugHUD,Exclusive/GameThread/RenderAssetStreaming,Exclusive/GameThread/EventWait/RenderAssetStreaming,Slate/GameThread/TickPlatform,Exclusive/GameThread/UI,Slate/GameThread/DrawPrePass,FileIO/QueuedPackagesQueueDepth,FileIO/ExistingQueuedPackagesQueueDepth,NavTasks/NumRemainingTasks_RecastNavMesh-Default,Basic/TicksQueued,ChaosPhysics/AABBTreeDirtyElementCount,ChaosPhysics/AABBTreeDirtyGridOverflowCount,ChaosPhysics/AABBTreeDirtyElementTooLargeCount,ChaosPhysics/AABBTreeDirtyElementNonEmptyCellCount,Ticks/ChaosDebugDrawComponent,Ticks/AbstractNavData,Ticks/RecastNavMesh,Ticks/SkeletalMeshComponent,Ticks/LineBatchComponent,Ticks/PhysicsFieldComponent,Ticks/FNiagaraWorldManagerTickFunction,Ticks/ParticleSystemManager,Ticks/StartPhysicsTick,Ticks/EndPhysicsTick,Ticks/Total,ActorCount/Actor,ActorCount/StaticMeshActor,ActorCount/GroupActor,ActorCount/RectLight,ActorCount/TotalActorCount,TextureStreaming/StreamingPool,TextureStreaming/SafetyPool,TextureStreaming/TemporaryPool,TextureStreaming/CachedMips,TextureStreaming/WantedMips,TextureStreaming/ResidentMeshMem,TextureStreaming/StreamedMeshMem,TextureStreaming/NonStreamingMips,TextureStreaming/PendingStreamInData,TextureStreaming/RenderAssetStreamingUpdate,CsvProfiler/NumTimestampsProcessed,CsvProfiler/NumCustomStatsProcessed,CsvProfiler/NumEventsProcessed,CsvProfiler/ProcessCSVStats,Exclusive/AllWorkers/Material_UpdateDeferredCachedUniformExpressions,Exclusive/AllWorkers/InitRenderResource,Scheduler/RHIThread/SignalStandbyThread,TransientResourceCreateCount,TransientMemoryUsedMB,TransientMemoryAliasedMB,GPUMem/LocalBudgetMB,GPUMem/LocalUsedMB,GPUMem/SystemBudgetMB,GPUMem/SystemUsedMB,RHI/DrawCalls,RHI/PrimitivesDrawn,DrawCall/SlateUI,DrawCall/Basepass,DrawCall/CustomDepth,DrawCall/VirtualTextureUpdate,DrawCall/Prepass,DrawCall/Distortion,DrawCall/Fog,DrawCall/Lights,DrawCall/BeginOcclusionTests,DrawCall/ScreenSpaceReflections,DrawCall/ShadowDepths,DrawCall/SingleLayerWaterDepthPrepass,DrawCall/SingleLayerWater,DrawCall/Translucency,DrawCall/RenderVelocities,DrawCall/WaterInfoTexture,DrawCall/FXSystemPreInitViews,DrawCall/FXSystemPreRender,DrawCall/FXSystemPostRenderOpaque,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheRayTracingPrimitives,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheRayTracingPrimitives_Merge,Exclusive/AllWorkers/RenderShadows,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheNaniteMaterialBins,SceneCulling/AllWorkers/PostSceneUpdate,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheMeshDrawCommands,Exclusive/AllWorkers/ShadowInitDynamic,SceneCulling/AllWorkers/PreSceneUpdate,Exclusive/RenderThread/RenderThreadOther,Exclusive/RenderThread/InitRenderResource,Exclusive/RenderThread/EventWait,Exclusive/RenderThread/RemovePrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveInstances,Exclusive/RenderThread/ConsolidateInstanceDataAllocations,Exclusive/RenderThread/AddPrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveTransform,Exclusive/RenderThread/PreRender,Exclusive/RenderThread/UpdateGPUScene,Exclusive/RenderThread/PrepareDistanceFieldScene,Exclusive/RenderThread/RenderOther,Exclusive/RenderThread/InitViews_Scene,Exclusive/RenderThread/Niagara,Exclusive/RenderThread/InitViews_Shadows,Exclusive/RenderThread/EventWait/Visibility,Exclusive/RenderThread/FXSystem,Exclusive/RenderThread/GPUSort,Exclusive/RenderThread/UploadDynamicPrimitiveShaderData,Exclusive/RenderThread/RenderPrePass,Exclusive/RenderThread/RenderVelocities,Exclusive/RenderThread/ShadowInitDynamic,Exclusive/RenderThread/EventWait/Shadows,Exclusive/RenderThread/SortLights,Exclusive/RenderThread/ComputeLightGrid,Exclusive/RenderThread/LightFunctionAtlasGeneration,Exclusive/RenderThread/RenderCustomDepthPass,Exclusive/RenderThread/DeferredShadingSceneRenderer_DBuffer,Exclusive/RenderThread/RenderBasePass,Exclusive/RenderThread/RenderShadows,Exclusive/RenderThread/AfterBasePass,Exclusive/RenderThread/RenderLighting,Exclusive/RenderThread/RenderIndirectCapsuleShadows,Exclusive/RenderThread/RenderFog,Exclusive/RenderThread/RenderLocalFogVolume,Exclusive/RenderThread/RenderOpaqueFX,Exclusive/RenderThread/RenderTranslucency,Exclusive/RenderThread/RenderPostProcessing,Exclusive/RenderThread/RDG,Exclusive/RenderThread/STAT_RDG_FlushResourcesRHI,Exclusive/RenderThread/RDG_CollectResources,Exclusive/RenderThread/RDG_Execute,Exclusive/RenderThread/PostRenderCleanUp,Exclusive/RenderThread/Material_UpdateDeferredCachedUniformExpressions,Exclusive/RenderThread/Slate,DrawSceneCommand_StartDelay,GPUSceneInstanceCount,DistanceField/AtlasMB,DistanceField/IndirectionTableMB,DistanceField/IndirectionAtlasMB,LightCount/All,LightCount/Batched,LightCount/Unbatched,LumenSceneDirectLighting/LightIdMod256CollisionCount,LumenSceneDirectLighting/LightIdMod256CollisionRate,PSO/PSOMisses,PSO/PSOMissesOnHitch,PSO/PSOPrevFrameMissesOnHitch,PSO/PSOComputeMisses,PSO/PSOComputeMissesOnHitch,PSO/PSOComputePrevFrameMissesOnHitch,RayTracingGeometry/RequestedSizeMB,RayTracingGeometry/TotalResidentSizeMB,RayTracingGeometry/TotalAlwaysResidentSizeMB,RenderTargetPool/UnusedMB,RenderTargetPool/PeakUsedMB,RenderTargetPoolSize,RenderTargetPoolUsed,RenderTargetPoolCount,RDGCount/Passes,RDGCount/Buffers,RDGCount/Textures,RenderThreadIdle/Total,RenderThreadIdle/CriticalPath,RenderThreadIdle/SwapBuffer,RenderThreadIdle/NonCriticalPath,RenderThreadIdle/GPUQuery,RenderTargetProfiler/ParticleCurveTexture,RenderTargetWasteProfiler/ParticleCurveTexture,RenderTargetProfiler/FParticleStatePosition,RenderTargetWasteProfiler/FParticleStatePosition,RenderTargetProfiler/FParticleStateVelocity,RenderTargetWasteProfiler/FParticleStateVelocity,RenderTargetProfiler/FParticleAttributesTexture,RenderTargetWasteProfiler/FParticleAttributesTexture,RenderTargetProfiler/BackBuffer0,RenderTargetWasteProfiler/BackBuffer0,RenderTargetProfiler/BackBuffer1,RenderTargetWasteProfiler/BackBuffer1,RenderTargetProfiler/BackBuffer2,RenderTargetWasteProfiler/BackBuffer2,RenderTargetProfiler/HitProxyTexture,RenderTargetWasteProfiler/HitProxyTexture,RenderTargetProfiler/BufferedRT,RenderTargetWasteProfiler/BufferedRT,RenderTargetProfiler/HairLUT0,RenderTargetWasteProfiler/HairLUT0,RenderTargetProfiler/CombineLUTs,RenderTargetWasteProfiler/CombineLUTs,RenderTargetProfiler/SceneDepthZ,RenderTargetWasteProfiler/SceneDepthZ,RenderTargetProfiler/SceneColor,RenderTargetWasteProfiler/SceneColor,RenderTargetProfiler/???RT????,RenderTargetWasteProfiler/???RT????,RenderTargetProfiler/???RT?????,RenderTargetWasteProfiler/???RT?????,RenderTargetProfiler/???RT??1,RenderTargetWasteProfiler/???RT??1,RenderTargetProfiler/???RT??2,RenderTargetWasteProfiler/???RT??2,RenderTargetProfiler/???RT??3,RenderTargetWasteProfiler/???RT??3,RenderTargetProfiler/???RT Mip 1,RenderTargetWasteProfiler/???RT Mip 1,RenderTargetProfiler/???RT Mip 2,RenderTargetWasteProfiler/???RT Mip 2,RenderTargetProfiler/???RT Mip 3,RenderTargetWasteProfiler/???RT Mip 3,RenderTargetProfiler/???RT Mip 4,RenderTargetWasteProfiler/???RT Mip 4,RenderTargetProfiler/???RT Mip 5,RenderTargetWasteProfiler/???RT Mip 5,RenderTargetProfiler/???RT??RGBA,RenderTargetWasteProfiler/???RT??RGBA,RenderTargetProfiler/???RT Mip 0,RenderTargetWasteProfiler/???RT Mip 0,RenderTargetProfiler/FLandscapeTexture2DResource,RenderTargetWasteProfiler/FLandscapeTexture2DResource,RenderTargetProfiler/Lumen.SceneDepth,RenderTargetWasteProfiler/Lumen.SceneDepth,RenderTargetProfiler/Lumen.SceneOpacity,RenderTargetWasteProfiler/Lumen.SceneOpacity,RenderTargetProfiler/Lumen.SceneDirectLighting,RenderTargetWasteProfiler/Lumen.SceneDirectLighting,RenderTargetProfiler/Lumen.SceneIndirectLighting,RenderTargetWasteProfiler/Lumen.SceneIndirectLighting,RenderTargetProfiler/Lumen.SceneNumFramesAccumulatedAtlas,RenderTargetWasteProfiler/Lumen.SceneNumFramesAccumulatedAtlas,RenderTargetProfiler/Lumen.SceneFinalLighting,RenderTargetWasteProfiler/Lumen.SceneFinalLighting,TextureProfiler/FSlateTexture2DRHIRef,TextureWasteProfiler/FSlateTexture2DRHIRef,TextureProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureWasteProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureProfiler/Shadow.Virtual.PhysicalPagePool,TextureWasteProfiler/Shadow.Virtual.PhysicalPagePool,TextureProfiler/Shadow.Virtual.HZBPhysicalPagePool,TextureWasteProfiler/Shadow.Virtual.HZBPhysicalPagePool,TextureProfiler/DistanceFields.DistanceFieldBrickTexture,TextureWasteProfiler/DistanceFields.DistanceFieldBrickTexture,TextureProfiler/GlobalDistanceField.PageAtlas,TextureWasteProfiler/GlobalDistanceField.PageAtlas,TextureProfiler/T_Wall_Normal,TextureWasteProfiler/T_Wall_Normal,TextureProfiler/T_Poster,TextureWasteProfiler/T_Poster,TextureProfiler/T_st_exp,TextureWasteProfiler/T_st_exp,TextureProfiler/T_Book,TextureWasteProfiler/T_Book,TextureProfiler/Lumen.RadianceCache.RadianceProbeAtlasTextureSource,TextureWasteProfiler/Lumen.RadianceCache.RadianceProbeAtlasTextureSource,TextureProfiler/Lumen.RadianceCache.FinalRadianceAtlas,TextureWasteProfiler/Lumen.RadianceCache.FinalRadianceAtlas,TextureProfiler/Lumen.SceneAlbedo,TextureWasteProfiler/Lumen.SceneAlbedo,TextureProfiler/Lumen.SceneNormal,TextureWasteProfiler/Lumen.SceneNormal,TextureProfiler/Lumen.SceneEmissive,TextureWasteProfiler/Lumen.SceneEmissive,TextureProfiler/Lumen.ScreenProbeGather.DiffuseIndirect,TextureWasteProfiler/Lumen.ScreenProbeGather.DiffuseIndirect,TextureProfiler/Lumen.Reflections.SpecularAndSecondMoment,TextureWasteProfiler/Lumen.Reflections.SpecularAndSecondMoment,TextureProfiler/T_Book_01,TextureWasteProfiler/T_Book_01,RenderTargetProfiler/Total,RenderTargetWasteProfiler/Total,RenderTargetProfiler/Other,RenderTargetWasteProfiler/Other,TextureProfiler/Total,TextureWasteProfiler/Total,TextureProfiler/Other,TextureWasteProfiler/Other,Slate/GameThread/DrawWindows_Private,Exclusive/GameThread/DeferredTickTime,Exclusive/GameThread/EOSSDK,Exclusive/GameThread/CsvProfiler,Exclusive/GameThread/LLM,IoDispatcher/PendingIoRequests,HttpManager/RequestsInQueue,HttpManager/MaxRequestsInQueue,HttpManager/RequestsInFlight,HttpManager/MaxRequestsInFlight,HttpManager/MaxTimeToWaitInQueue,HttpManager/DownloadedMB,HttpManager/BandwidthMbps,HttpManager/DurationMsAvg,Shaders/ShaderMemoryMB,Shaders/NumShadersLoaded,Shaders/NumShaderMaps,Shaders/NumShadersCreated,Shaders/NumShaderMapsUsedForRendering,FrameTime,MemoryFreeMB,PhysicalUsedMB,VirtualUsedMB,ExtendedUsedMB,SystemMaxMB,RenderThreadTime,GameThreadTime,GPUTime,RenderThreadTime_CriticalPath,GameThreadTime_CriticalPath,RHIThreadTime,InputLatencyTime,MaxFrameTime,CPUUsage_Process,CPUUsage_Idle,Scheduler/GameThread/SignalStandbyThread,Scheduler/RenderThread/SignalStandbyThread,Scheduler/RHIInterruptThread/SignalStandbyThread,FMsgLogf/FMsgLogfCount
,0.7269,0.046900,0.016500,0.2499,0.8295,0.007000,0.022000,0.003300,0.077100,0.2128,0.1600,0.011700,0.058100,0.018800,0.084100,0.079100,0.013300,6,0,2,0.027400,0.004700,0.013800,0.2267,0.099300,0.088000,0.002400,0.001300,0.006000,0.003700,0.018900,0.000700,0.006900,0.022800,0.091400,0.013700,0.046300,0.091500,0.006700,0.000600,0.1063,0.073300,0.000800,0.001100,0.010300,0.001100,0.037200,0.011000,0.076800,0.088400,0.003300,0.6621,7.9461,2.7335,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,287,217,0,0.2009,0.012700,0,0,1,128,77.5000,15409,3347.0977,13502.1543,316.1602,5718,4924167,225,442,55,0,367,0,0,30,369,0,3883,0,0,251,32,0,0,0,0,0.005600,0.000400,2.4235,0.004200,0.013600,0.029600,0,0.002800,2.3388,0.073900,0.6233,0.000700,0.001600,0.000900,0.001200,0.018600,0.022900,0.2261,0.039800,2.3078,0.2660,0.017800,0.009500,12.3392,0.036800,0.015600,0.1166,0.023400,0.014600,0.081000,2.9064,0.002500,0.052000,0.002800,0.014700,0.018600,0.029600,0.2749,0.005500,1.1196,0.000500,0.000800,0.000400,0.055000,0.058400,0.3000,0.3310,0.025700,0.4768,0.3323,0.003200,0.001000,0.1062,7.9918,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3201,218.3201,155.8613,0,796.1680,796.1680,796.1680,67,402,348,231,0.2668,0.2668,0.008100,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.3014,0.1475,0.080100,0.007100,0.000100,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,13.1926,7623.4492,2450.9102,8419.4453,0,10074.2148,21.3392,17.5947,20.5680,21.7562,17.5947,0.2726,73.8392,33.3333,0.059274,0.1831,0,0,0,0
,0.9252,0.045100,0.020900,0.1410,0.4329,0.005500,0.022900,0.002400,0.1226,0.080700,0.1487,0.012100,0.2400,0.022800,0.1272,0.1001,0.008100,6,0,3,0.022700,0.007800,0.010900,11.0997,0.082100,0.076500,0.011900,0.001200,0.005200,0.003000,0.016800,0.000700,0.005200,0.038300,0.074800,0.012800,0.037300,0.088200,0.004600,0.000600,0.077100,0.067200,0.000700,0.000100,0.010000,0.001100,0.027500,0.006900,0.050600,0.053300,0.002600,0.2587,5.5065,1.9141,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,0,0,0,0,0,0.040000,0.002700,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5659,4955997,227,427,55,0,352,0,0,30,348,0,3883,0,0,251,32,0,0,0,0,0,0,0,0,0,0,4.0297,0,1.5097,0.071900,0.5370,0.000500,0.001400,0.001000,0.000700,0.016000,0.028300,0.2382,0.062500,2.4358,0.2846,0.021300,0.028300,10.1908,0.041400,0.016100,0.1137,0.027500,0.012800,0.098200,2.3015,0.002900,0.047200,0.002600,0.016100,0.014600,0.029400,0.2389,0.005700,0.9708,0.000900,0.000500,0.000300,0.062800,0.054800,0.3197,0.4014,0.033700,0.7443,0.3532,0.003900,0.001500,0.1975,17.5231,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3201,218.3201,155.8613,0,796.1680,796.1680,796.1680,67,417,348,231,0.3400,0.3400,0.014800,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.2677,0.1076,0.076900,0.007600,0.000200,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,22.6407,7619.1289,2450.9141,8419.4453,0,10074.3633,24.5591,11.0374,20.6704,24.8259,11.0374,5.7212,73.8392,33.3333,0.064491,0.2003,0,0,0,0
,0.6133,0.041600,0.017800,0.1886,0.4429,0.004200,0.016200,0.004900,0.059500,0.079900,0.1519,0.011900,0.054600,0.014200,0.1751,0.069100,0.009000,6,0,3,0.035500,0.006800,0.015700,13.7588,0.1067,0.087500,0.001300,0.001600,0.005100,0.003600,0.017800,0.001500,0.006400,0.015000,0.068100,0.011000,0.030400,0.065800,0.005600,0.000800,0.1117,0.096200,0.001800,0.000100,0.010300,0.001300,0.030500,0.007600,0.051000,0.033400,0.003500,0.1915,4.5093,1.8739,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,0,0,0,0,0.019500,0.053200,0.003500,2,128,77.5000,15409,3347.0977,13502.1543,316.1602,5727,5088209,227,443,55,0,368,0,0,30,364,0,3883,0,0,251,32,0,0,0,0,0.008000,0.000300,2.9750,0.005200,0.015900,0.039200,3.4279,0.002600,1.5199,0.090400,0.7636,0.000700,0.001500,0.001200,0.000700,0.018900,0.028300,0.2195,0.059700,2.6769,0.1481,0.020900,0.014200,8.6004,0.033100,0.013100,0.1276,0.022000,0.015400,0.1546,5.0020,0.004400,0.093900,0.003800,0.023700,0.016300,0.031300,0.2500,0.006100,1.1948,0.000600,0.000700,0.000400,0.050300,0.056700,0.3424,0.4460,0.024900,0.4814,0.3103,0.003600,0.000800,0.092700,18.7295,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,417,348,231,0.5326,0.5326,0.008800,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.2003,0.1625,0.095800,0.008700,0.000300,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,21.7747,7619.1289,2450.9141,8419.4453,0,10070.0430,21.2979,9.6450,20.0867,21.6379,9.6450,5.3174,73.8392,33.3333,0.078307,0.1981,0,0,0,0
,1.0683,0.053700,0.015700,0.1113,0.4309,0.006000,0.019100,0.003400,0.056500,0.1144,0.1730,0.015600,0.057500,0.018900,0.1334,0.1440,0.1567,6,0,4,0.018700,0.004700,0.014700,14.2554,0.1010,0.099900,0.001400,0.001900,0.005800,0.003900,0.019100,0.000900,0.006000,0.016600,0.086000,0.014200,0.042800,0.1299,0.006800,0.000800,0.099800,0.071100,0.000800,0.000100,0.011500,0.001200,0.045300,0.010300,0.1584,0.1287,0.003400,0.5494,5.1523,2.0693,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0.1325,1037,588,0,0.5194,0.018700,0.042400,0.008400,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5692,5291480,227,427,55,0,352,0,0,30,356,0,3883,0,0,251,32,0,0,0,0,0.007900,0.000400,1.0110,0.004400,0.013400,0.029600,5.6420,0.002400,1.0460,0.065600,0.5327,0.000600,0.001500,0.000900,0.000500,0.016800,0.027600,0.2408,0.053100,2.7275,0.2116,0.017800,0.013400,8.2136,0.032300,0.014700,0.1449,0.041300,0.033100,0.1100,2.6316,0.003700,0.057700,0.003200,0.019600,0.011600,0.030800,0.2493,0.006300,1.0277,0.000500,0.000800,0.000500,0.069200,0.082600,0.3165,0.3452,0.022100,0.4610,0.3124,0.003400,0.000900,0.1391,20.3811,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,417,348,231,0.2976,0.2976,0.006000,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.1836,0.1065,0.068800,0.006500,0.000100,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,23.0936,7619.0547,2450.9141,8419.4453,0,10070.0430,22.6812,7.8719,19.7371,23.2138,7.8719,7.4598,73.8392,33.3333,0.085187,0.1588,0,0,0,0
,0.6363,0.057800,0.016900,0.1671,0.4278,0.004800,0.021700,0.004600,0.1794,0.079500,0.1399,0.009500,0.042900,0.014100,0.1341,0.1493,0.016800,6,0,3,0.031400,0.004200,0.014200,9.1632,0.1108,0.083200,0.001100,0.001000,0.004600,0.002600,0.013800,0.000700,0.004600,0.011700,0.070200,0.010800,0.029800,0.1482,0.004000,0.000600,0.1231,0.1059,0.001000,0.000200,0.015600,0.001800,0.046200,0.008900,0.066100,0.060000,0.002900,0.2920,6.7375,2.5130,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,0,0,0,0,0.014400,0.027600,0.004000,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5688,4793355,227,426,55,0,351,0,0,30,357,0,3883,0,0,251,32,0,0,0,0,0.008500,0.000400,1.0803,0.004400,0.011000,0.022100,4.1049,0.002900,1.0873,0.056100,0.4979,0.000500,0.001100,0.002500,0.000600,0.013000,0.038700,0.1776,0.056100,2.1901,0.1403,0.020200,0.014600,13.7010,0.027700,0.012900,0.079600,0.019900,0.015600,0.091600,2.6820,0.004100,0.065700,0.005000,0.022900,0.017000,0.030200,0.2193,0.006100,1.0024,0.000500,0.000900,0.000400,0.054900,0.055000,0.2792,0.3541,0.020400,0.4547,0.2949,0.003200,0.000900,0.1057,16.5378,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,406,348,231,0.2811,0.2811,0.008200,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.6126,0.1033,0.064400,0.008500,0.000100,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,19.4666,7620.1133,2450.9141,8419.4453,0,10069.9688,19.1584,9.2797,20.1260,19.4560,9.2797,6.4138,71.5988,33.3333,0.093867,0.1870,0.007700,0,0,0
,0.6239,0.042600,0.014700,0.1312,0.4730,0.005300,0.016400,0.004500,0.1407,0.1179,0.1629,0.011100,0.043900,0.022100,0.1321,0.2475,0.016800,6,0,5,0.025300,0.004800,0.012300,15.8006,0.1265,0.1441,0.002000,0.002100,0.007300,0.005100,0.023500,0.001100,0.008400,0.022600,0.095000,0.017800,0.065000,0.2122,0.007200,0.000800,0.1416,0.099300,0.001300,0.000100,0.015200,0.001200,0.051100,0.009300,0.1191,0.056700,0.001900,0.2593,5.1160,1.9605,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,847,515,0,0.2144,0.009900,0.039100,0.010700,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5659,4719193,227,426,55,0,351,0,0,30,348,0,3883,0,0,251,32,0,0,0,0,0.005300,0.000400,1.0106,0.003700,0.013800,0.023200,3.3766,0.001700,1.0709,0.067900,0.4919,0.000500,0.001000,0.000900,0.000800,0.021000,0.018500,0.1963,0.052900,2.5510,0.1433,0.018600,0.013500,12.1551,0.027900,0.014400,0.1160,0.038400,0.024700,0.091800,4.3713,0.003300,0.054400,0.002800,0.017300,0.015500,0.026900,0.2505,0.004900,0.9222,0.000500,0.000600,0.000300,0.046000,0.048600,0.2542,0.3390,0.019900,0.5832,0.3027,0.002900,0.000800,0.1792,21.6763,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,407,348,231,0.2748,0.2748,0.013200,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.1844,0.1039,0.061200,0.006200,0,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,24.0452,7619.1758,2450.9180,8419.4453,0,10071.0312,23.7793,9.8944,20.0910,24.0604,9.8944,6.0184,71.5988,33.3333,0.069554,0.2101,0,0.005700,0,0
,0.5753,0.039800,0.015700,0.1310,0.4203,0.003500,0.020100,0.003100,0.069000,0.1159,0.1312,0.015000,0.047700,0.015900,0.1715,0.088700,0.063600,6,0,4,0.027400,0.007800,0.038900,16.9161,0.1253,0.095900,0.001400,0.001000,0.005100,0.003400,0.015900,0.000600,0.005400,0.014900,0.079200,0.014800,0.041100,0.087000,0.005300,0.000900,0.3347,0.1003,0.001100,0.000100,0.016100,0.001600,0.044200,0.006500,0.079600,0.052200,0.002400,0.2761,4.9722,1.9142,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,0,0,0,0,0.009500,0.032500,0.006000,1,128,77.5000,15409,3347.0977,13502.1543,316.1602,5704,4872412,227,441,55,0,366,0,0,30,362,0,3883,0,0,251,32,0,0,0,0,0.005400,0.000200,1.4644,0.004200,0.016500,0.028500,5.8317,0.011700,1.5532,0.059000,0.8093,0.000700,0.001600,0.001300,0.000800,0.018100,0.022000,0.1989,0.042000,2.7865,0.1454,0.020300,0.012900,9.3118,0.053300,0.021300,0.1113,0.028100,0.029400,0.073200,2.2228,0.003100,0.050000,0.002600,0.015600,0.014500,0.053900,0.3419,0.008900,1.7062,0.000800,0.000700,0.001000,0.083100,0.069800,0.4291,0.7924,0.060400,0.7401,0.3929,0.006200,0.001700,0.1889,22.8208,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,401,348,231,0.4406,0.4406,0.011000,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.1701,0.1518,0.2005,0.008200,0.000200,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,24.8821,7620.2656,2450.9180,8419.4453,0,10070.0938,24.3866,8.3730,20.4618,24.6614,8.3730,5.0968,82.0161,33.3333,0.068532,0.2252,0,0.003500,0,0
,0.9339,0.057200,0.025500,0.1820,0.9568,0.008700,0.030900,0.004700,0.1040,0.1041,0.2141,0.016200,0.091600,0.027900,0.4665,0.1342,0.030700,6,0,3,0.039200,0.004200,0.1728,15.0879,0.082400,0.086400,0.001700,0.001200,0.005200,0.003900,0.017500,0.000900,0.007600,0.015600,0.066100,0.014500,0.054300,0.097700,0.003700,0.000600,0.068700,0.057300,0.000600,0.000100,0.009900,0.001200,0.033200,0.009300,0.083200,0.075400,0.003500,0.3000,4.3692,1.7513,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,895,544,0,0.2801,0.014900,0.054700,0.004800,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5658,4708564,227,426,55,0,351,0,0,30,348,0,3883,0,0,251,32,0,0,0,0,0.006300,0.000400,0,0.004900,0.037900,0.024900,3.4072,0.001700,2.2075,0.090300,0.9203,0.000700,0.002400,0.002100,0.001500,0.024500,0.022300,0.2053,0.075900,3.7505,0.3233,0.023500,0.013000,6.7466,0.046500,0.018400,0.1374,0.058700,0.041600,0.1637,7.4711,0.004400,0.091400,0.003900,0.025100,0.021900,0.052800,0.4813,0.011400,2.0381,0.001100,0.001000,0.000500,0.068700,0.1048,0.5940,0.4734,0.037800,0.8980,0.3846,0.004800,0.001200,0.2043,21.0323,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,404,348,231,0.4933,0.4933,0.008400,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.1859,0.1434,0.095200,0.008400,0.000300,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,22.5565,7613.7891,2450.9180,8419.4453,0,10071.1836,22.2039,8.1338,19.7266,22.6445,8.1338,5.6378,82.0161,33.3333,0.084785,0.1604,0.006000,0,0,0
,0.8178,0.048300,0.020400,0.1585,1.1295,0.008000,0.020700,0.003800,0.3303,0.1060,0.1737,0.012700,0.065500,0.022500,0.2253,0.093200,0,6,0,3,0.041500,0.005400,0.018100,11.6458,0.1789,0.1191,0.001900,0.002000,0.008500,0.007000,0.042100,0.001400,0.007600,0.028100,0.088500,0.016900,0.043700,0.092700,0.008100,0.001500,0.2746,0.1235,0.001100,0.000100,0.017500,0.002500,0.057800,0.011700,0.2625,0.081900,0.030100,0.6904,12.0056,5.1583,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,0,0,0,0,0.021500,0.015300,0.002300,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5715,4764264,227,442,55,0,367,0,0,30,369,0,3883,0,0,251,32,0,0,0,0,0.008700,0.000400,2.4988,0.006900,0.017800,0.033700,9.1396,0.002400,1.9345,0.067300,0.6895,0.000900,0.002200,0.001900,0.001200,0.022200,0.039600,0.2009,0.060800,2.8129,0.2888,0.021100,0.016000,10.3081,0.043000,0.015500,0.1355,0.050500,0.035900,0.1053,4.1037,0.003100,0.060300,0.003900,0.020500,0.012000,0.029900,0.2446,0.005600,1.0865,0.000700,0.001800,0.000400,0.056300,0.062000,0.3090,0.3391,0.049800,0.5223,0.3640,0.003200,0.001300,0.1144,25.5423,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,410,348,231,0.2807,0.2807,0.011000,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.2700,0.1302,0.1253,0.008800,0.000300,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,28.0534,7588.3945,2450.9219,8419.4453,0,10064.7109,27.5239,8.0841,20.3993,28.0172,8.0841,8.7726,79.1725,33.3333,0.093018,0.003433,0,0,0,0
,1.1681,0.033300,0.016000,0.1109,0.4899,0.006600,0.016500,0.002300,0.066800,0.1194,0.1558,0.018000,0.065800,0.014900,0.1582,0.1979,0.007000,6,0,3,0.088700,0.004600,0.015000,13.1507,0.2621,0.1311,0.002000,0.002700,0.092600,0.006100,0.1141,0.001600,0.008600,0.022400,0.1258,0.1188,0.091800,0.1583,0.006200,0.001600,0.1271,0.1531,0.001400,0.000100,0.017200,0.001600,0.065100,0.011200,0.091400,0.049300,0.004900,0.4588,6.9857,3.1068,0,0,0,24,0,0,0,0,1,1,1,1,3,1,7,7,1,1,24,88,233,11,7,361,77.2227,5,50,7.8516,77.2227,0,0,838.3672,0,0,801,487,0,0.4996,0.021300,0.039700,0.003900,0,128,77.5000,15409,3347.0977,13502.1543,316.1602,5655,4789744,227,427,55,0,352,0,0,30,340,0,3883,0,0,251,32,0,0,0,0,0.007500,0.000500,3.2239,0.005400,0.016200,0.042300,5.5301,0.002600,1.5598,0.078000,0.4675,0.000800,0.001300,0.001000,0.001100,0.017000,0.026500,0.1944,0.080100,2.0100,0.1726,0.019200,0.014600,6.7990,0.036500,0.021700,0.1222,0.022100,0.017500,0.1016,5.3292,0.003600,0.057600,0.002800,0.019300,0.014000,0.029200,0.2394,0.005100,1.1892,0.000600,0.000600,0.000400,0.057400,0.096400,0.4399,0.8084,0.024600,0.6946,0.4059,0.003800,0.001100,0.1077,21.2841,4396,16,0.1250,0,16,8,8,0,0,0,-1,-1,0,-1,-1,218.3203,218.3203,155.8613,0,796.1680,796.1680,796.1680,67,394,348,231,0.045700,0.045700,0.009400,0,0,1,0,32,0,16,0,8,0,17,0,17,0,17,0,5,0,5,0,1,0,1,0,9,0,9,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0,32,0,16,0,64,0,64,0,16,0,64,0,29,0,17,0,256,0,43,0,16,0,16,0,22,0,16,0,43,0,295,0,20,0,42,0,16,0,16,0,16,0,17,0,17,0,373,0,391,0,0,0,1447,0,190,0,0.2442,0.1117,0.077200,0.085500,0.000100,0,0,0,0,1,0,0,0,243,7.7947,13895,347,768,173,24.4230,7569.7656,2450.9258,8419.4453,0,10039.3203,24.1449,17.2294,19.3179,24.4256,17.2294,8.5496,79.1725,33.3333,0.084426,0.1134,0,0,0,2
EVENTS,Exclusive/AllWorkers/RenderLighting,Exclusive/AllWorkers/UpdateGPUScene,Exclusive/AllWorkers/PrepareDistanceFieldScene,Exclusive/AllWorkers/RenderBasePass,Exclusive/AllWorkers/RenderPostProcessing,Exclusive/AllWorkers/SortLights,Exclusive/AllWorkers/ComputeLightGrid,Exclusive/AllWorkers/LightFunctionAtlasGeneration,Exclusive/AllWorkers/RenderCustomDepthPass,Exclusive/AllWorkers/Effects,Exclusive/AllWorkers/RenderPrePass,Exclusive/AllWorkers/RenderVelocities,Exclusive/AllWorkers/RenderTranslucency,Exclusive/AllWorkers/UploadDynamicPrimitiveShaderData,Exclusive/AllWorkers/Slate,Exclusive/AllWorkers/Physics,Scheduler/AllWorkers/SignalStandbyThread,LightCount/UpdatedShadowMaps,ShadowCacheUsageMB,Scheduler/Oversubscription,Exclusive/GameThread/Input,Exclusive/GameThread/TimerManager,Exclusive/GameThread/AsyncLoading,Exclusive/GameThread/EventWait,Exclusive/GameThread/WorldTickMisc,Exclusive/GameThread/Effects,Exclusive/GameThread/NetworkIncoming,NavigationBuildDetailed/GameThread/Navigation_RebuildDirtyAreas,NavigationBuildDetailed/GameThread/Navigation_TickAsyncBuild,NavigationBuildDetailed/GameThread/Navigation_CrowdManager,Exclusive/GameThread/NavigationBuild,Exclusive/GameThread/ResetAsyncTraceTickTime,Exclusive/GameThread/WorldPreActorTick,Exclusive/GameThread/QueueTicks,Exclusive/GameThread/TickActors,Exclusive/GameThread/Animation,Exclusive/GameThread/Physics,Exclusive/GameThread/EventWait/EndPhysics,Exclusive/GameThread/SyncBodies,Exclusive/GameThread/FlushLatentActions,Exclusive/GameThread/Tickables,Exclusive/GameThread/Landscape,Exclusive/GameThread/EnvQueryManager,Exclusive/GameThread/Camera,Exclusive/GameThread/RecordTickCountsToCSV,Exclusive/GameThread/RecordActorCountsToCSV,Exclusive/GameThread/EndOfFrameUpdates,Exclusive/GameThread/Audio,Exclusive/GameThread/DebugHUD,Exclusive/GameThread/RenderAssetStreaming,Exclusive/GameThread/EventWait/RenderAssetStreaming,Slate/GameThread/TickPlatform,Exclusive/GameThread/UI,Slate/GameThread/DrawPrePass,FileIO/QueuedPackagesQueueDepth,FileIO/ExistingQueuedPackagesQueueDepth,NavTasks/NumRemainingTasks_RecastNavMesh-Default,Basic/TicksQueued,ChaosPhysics/AABBTreeDirtyElementCount,ChaosPhysics/AABBTreeDirtyGridOverflowCount,ChaosPhysics/AABBTreeDirtyElementTooLargeCount,ChaosPhysics/AABBTreeDirtyElementNonEmptyCellCount,Ticks/ChaosDebugDrawComponent,Ticks/AbstractNavData,Ticks/RecastNavMesh,Ticks/SkeletalMeshComponent,Ticks/LineBatchComponent,Ticks/PhysicsFieldComponent,Ticks/FNiagaraWorldManagerTickFunction,Ticks/ParticleSystemManager,Ticks/StartPhysicsTick,Ticks/EndPhysicsTick,Ticks/Total,ActorCount/Actor,ActorCount/StaticMeshActor,ActorCount/GroupActor,ActorCount/RectLight,ActorCount/TotalActorCount,TextureStreaming/StreamingPool,TextureStreaming/SafetyPool,TextureStreaming/TemporaryPool,TextureStreaming/CachedMips,TextureStreaming/WantedMips,TextureStreaming/ResidentMeshMem,TextureStreaming/StreamedMeshMem,TextureStreaming/NonStreamingMips,TextureStreaming/PendingStreamInData,TextureStreaming/RenderAssetStreamingUpdate,CsvProfiler/NumTimestampsProcessed,CsvProfiler/NumCustomStatsProcessed,CsvProfiler/NumEventsProcessed,CsvProfiler/ProcessCSVStats,Exclusive/AllWorkers/Material_UpdateDeferredCachedUniformExpressions,Exclusive/AllWorkers/InitRenderResource,Scheduler/RHIThread/SignalStandbyThread,TransientResourceCreateCount,TransientMemoryUsedMB,TransientMemoryAliasedMB,GPUMem/LocalBudgetMB,GPUMem/LocalUsedMB,GPUMem/SystemBudgetMB,GPUMem/SystemUsedMB,RHI/DrawCalls,RHI/PrimitivesDrawn,DrawCall/SlateUI,DrawCall/Basepass,DrawCall/CustomDepth,DrawCall/VirtualTextureUpdate,DrawCall/Prepass,DrawCall/Distortion,DrawCall/Fog,DrawCall/Lights,DrawCall/BeginOcclusionTests,DrawCall/ScreenSpaceReflections,DrawCall/ShadowDepths,DrawCall/SingleLayerWaterDepthPrepass,DrawCall/SingleLayerWater,DrawCall/Translucency,DrawCall/RenderVelocities,DrawCall/WaterInfoTexture,DrawCall/FXSystemPreInitViews,DrawCall/FXSystemPreRender,DrawCall/FXSystemPostRenderOpaque,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheRayTracingPrimitives,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheRayTracingPrimitives_Merge,Exclusive/AllWorkers/RenderShadows,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheNaniteMaterialBins,SceneCulling/AllWorkers/PostSceneUpdate,Exclusive/AllWorkers/FPrimitiveSceneInfo_CacheMeshDrawCommands,Exclusive/AllWorkers/ShadowInitDynamic,SceneCulling/AllWorkers/PreSceneUpdate,Exclusive/RenderThread/RenderThreadOther,Exclusive/RenderThread/InitRenderResource,Exclusive/RenderThread/EventWait,Exclusive/RenderThread/RemovePrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveInstances,Exclusive/RenderThread/ConsolidateInstanceDataAllocations,Exclusive/RenderThread/AddPrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveTransform,Exclusive/RenderThread/PreRender,Exclusive/RenderThread/UpdateGPUScene,Exclusive/RenderThread/PrepareDistanceFieldScene,Exclusive/RenderThread/RenderOther,Exclusive/RenderThread/InitViews_Scene,Exclusive/RenderThread/Niagara,Exclusive/RenderThread/InitViews_Shadows,Exclusive/RenderThread/EventWait/Visibility,Exclusive/RenderThread/FXSystem,Exclusive/RenderThread/GPUSort,Exclusive/RenderThread/UploadDynamicPrimitiveShaderData,Exclusive/RenderThread/RenderPrePass,Exclusive/RenderThread/RenderVelocities,Exclusive/RenderThread/ShadowInitDynamic,Exclusive/RenderThread/EventWait/Shadows,Exclusive/RenderThread/SortLights,Exclusive/RenderThread/ComputeLightGrid,Exclusive/RenderThread/LightFunctionAtlasGeneration,Exclusive/RenderThread/RenderCustomDepthPass,Exclusive/RenderThread/DeferredShadingSceneRenderer_DBuffer,Exclusive/RenderThread/RenderBasePass,Exclusive/RenderThread/RenderShadows,Exclusive/RenderThread/AfterBasePass,Exclusive/RenderThread/RenderLighting,Exclusive/RenderThread/RenderIndirectCapsuleShadows,Exclusive/RenderThread/RenderFog,Exclusive/RenderThread/RenderLocalFogVolume,Exclusive/RenderThread/RenderOpaqueFX,Exclusive/RenderThread/RenderTranslucency,Exclusive/RenderThread/RenderPostProcessing,Exclusive/RenderThread/RDG,Exclusive/RenderThread/STAT_RDG_FlushResourcesRHI,Exclusive/RenderThread/RDG_CollectResources,Exclusive/RenderThread/RDG_Execute,Exclusive/RenderThread/PostRenderCleanUp,Exclusive/RenderThread/Material_UpdateDeferredCachedUniformExpressions,Exclusive/RenderThread/Slate,DrawSceneCommand_StartDelay,GPUSceneInstanceCount,DistanceField/AtlasMB,DistanceField/IndirectionTableMB,DistanceField/IndirectionAtlasMB,LightCount/All,LightCount/Batched,LightCount/Unbatched,LumenSceneDirectLighting/LightIdMod256CollisionCount,LumenSceneDirectLighting/LightIdMod256CollisionRate,PSO/PSOMisses,PSO/PSOMissesOnHitch,PSO/PSOPrevFrameMissesOnHitch,PSO/PSOComputeMisses,PSO/PSOComputeMissesOnHitch,PSO/PSOComputePrevFrameMissesOnHitch,RayTracingGeometry/RequestedSizeMB,RayTracingGeometry/TotalResidentSizeMB,RayTracingGeometry/TotalAlwaysResidentSizeMB,RenderTargetPool/UnusedMB,RenderTargetPool/PeakUsedMB,RenderTargetPoolSize,RenderTargetPoolUsed,RenderTargetPoolCount,RDGCount/Passes,RDGCount/Buffers,RDGCount/Textures,RenderThreadIdle/Total,RenderThreadIdle/CriticalPath,RenderThreadIdle/SwapBuffer,RenderThreadIdle/NonCriticalPath,RenderThreadIdle/GPUQuery,RenderTargetProfiler/ParticleCurveTexture,RenderTargetWasteProfiler/ParticleCurveTexture,RenderTargetProfiler/FParticleStatePosition,RenderTargetWasteProfiler/FParticleStatePosition,RenderTargetProfiler/FParticleStateVelocity,RenderTargetWasteProfiler/FParticleStateVelocity,RenderTargetProfiler/FParticleAttributesTexture,RenderTargetWasteProfiler/FParticleAttributesTexture,RenderTargetProfiler/BackBuffer0,RenderTargetWasteProfiler/BackBuffer0,RenderTargetProfiler/BackBuffer1,RenderTargetWasteProfiler/BackBuffer1,RenderTargetProfiler/BackBuffer2,RenderTargetWasteProfiler/BackBuffer2,RenderTargetProfiler/HitProxyTexture,RenderTargetWasteProfiler/HitProxyTexture,RenderTargetProfiler/BufferedRT,RenderTargetWasteProfiler/BufferedRT,RenderTargetProfiler/HairLUT0,RenderTargetWasteProfiler/HairLUT0,RenderTargetProfiler/CombineLUTs,RenderTargetWasteProfiler/CombineLUTs,RenderTargetProfiler/SceneDepthZ,RenderTargetWasteProfiler/SceneDepthZ,RenderTargetProfiler/SceneColor,RenderTargetWasteProfiler/SceneColor,RenderTargetProfiler/???RT????,RenderTargetWasteProfiler/???RT????,RenderTargetProfiler/???RT?????,RenderTargetWasteProfiler/???RT?????,RenderTargetProfiler/???RT??1,RenderTargetWasteProfiler/???RT??1,RenderTargetProfiler/???RT??2,RenderTargetWasteProfiler/???RT??2,RenderTargetProfiler/???RT??3,RenderTargetWasteProfiler/???RT??3,RenderTargetProfiler/???RT Mip 1,RenderTargetWasteProfiler/???RT Mip 1,RenderTargetProfiler/???RT Mip 2,RenderTargetWasteProfiler/???RT Mip 2,RenderTargetProfiler/???RT Mip 3,RenderTargetWasteProfiler/???RT Mip 3,RenderTargetProfiler/???RT Mip 4,RenderTargetWasteProfiler/???RT Mip 4,RenderTargetProfiler/???RT Mip 5,RenderTargetWasteProfiler/???RT Mip 5,RenderTargetProfiler/???RT??RGBA,RenderTargetWasteProfiler/???RT??RGBA,RenderTargetProfiler/???RT Mip 0,RenderTargetWasteProfiler/???RT Mip 0,RenderTargetProfiler/FLandscapeTexture2DResource,RenderTargetWasteProfiler/FLandscapeTexture2DResource,RenderTargetProfiler/Lumen.SceneDepth,RenderTargetWasteProfiler/Lumen.SceneDepth,RenderTargetProfiler/Lumen.SceneOpacity,RenderTargetWasteProfiler/Lumen.SceneOpacity,RenderTargetProfiler/Lumen.SceneDirectLighting,RenderTargetWasteProfiler/Lumen.SceneDirectLighting,RenderTargetProfiler/Lumen.SceneIndirectLighting,RenderTargetWasteProfiler/Lumen.SceneIndirectLighting,RenderTargetProfiler/Lumen.SceneNumFramesAccumulatedAtlas,RenderTargetWasteProfiler/Lumen.SceneNumFramesAccumulatedAtlas,RenderTargetProfiler/Lumen.SceneFinalLighting,RenderTargetWasteProfiler/Lumen.SceneFinalLighting,TextureProfiler/FSlateTexture2DRHIRef,TextureWasteProfiler/FSlateTexture2DRHIRef,TextureProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureWasteProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureProfiler/Shadow.Virtual.PhysicalPagePool,TextureWasteProfiler/Shadow.Virtual.PhysicalPagePool,TextureProfiler/Shadow.Virtual.HZBPhysicalPagePool,TextureWasteProfiler/Shadow.Virtual.HZBPhysicalPagePool,TextureProfiler/DistanceFields.DistanceFieldBrickTexture,TextureWasteProfiler/DistanceFields.DistanceFieldBrickTexture,TextureProfiler/GlobalDistanceField.PageAtlas,TextureWasteProfiler/GlobalDistanceField.PageAtlas,TextureProfiler/T_Wall_Normal,TextureWasteProfiler/T_Wall_Normal,TextureProfiler/T_Poster,TextureWasteProfiler/T_Poster,TextureProfiler/T_st_exp,TextureWasteProfiler/T_st_exp,TextureProfiler/T_Book,TextureWasteProfiler/T_Book,TextureProfiler/Lumen.RadianceCache.RadianceProbeAtlasTextureSource,TextureWasteProfiler/Lumen.RadianceCache.RadianceProbeAtlasTextureSource,TextureProfiler/Lumen.RadianceCache.FinalRadianceAtlas,TextureWasteProfiler/Lumen.RadianceCache.FinalRadianceAtlas,TextureProfiler/Lumen.SceneAlbedo,TextureWasteProfiler/Lumen.SceneAlbedo,TextureProfiler/Lumen.SceneNormal,TextureWasteProfiler/Lumen.SceneNormal,TextureProfiler/Lumen.SceneEmissive,TextureWasteProfiler/Lumen.SceneEmissive,TextureProfiler/Lumen.ScreenProbeGather.DiffuseIndirect,TextureWasteProfiler/Lumen.ScreenProbeGather.DiffuseIndirect,TextureProfiler/Lumen.Reflections.SpecularAndSecondMoment,TextureWasteProfiler/Lumen.Reflections.SpecularAndSecondMoment,TextureProfiler/T_Book_01,TextureWasteProfiler/T_Book_01,RenderTargetProfiler/Total,RenderTargetWasteProfiler/Total,RenderTargetProfiler/Other,RenderTargetWasteProfiler/Other,TextureProfiler/Total,TextureWasteProfiler/Total,TextureProfiler/Other,TextureWasteProfiler/Other,Slate/GameThread/DrawWindows_Private,Exclusive/GameThread/DeferredTickTime,Exclusive/GameThread/EOSSDK,Exclusive/GameThread/CsvProfiler,Exclusive/GameThread/LLM,IoDispatcher/PendingIoRequests,HttpManager/RequestsInQueue,HttpManager/MaxRequestsInQueue,HttpManager/RequestsInFlight,HttpManager/MaxRequestsInFlight,HttpManager/MaxTimeToWaitInQueue,HttpManager/DownloadedMB,HttpManager/BandwidthMbps,HttpManager/DurationMsAvg,Shaders/ShaderMemoryMB,Shaders/NumShadersLoaded,Shaders/NumShaderMaps,Shaders/NumShadersCreated,Shaders/NumShaderMapsUsedForRendering,FrameTime,MemoryFreeMB,PhysicalUsedMB,VirtualUsedMB,ExtendedUsedMB,SystemMaxMB,RenderThreadTime,GameThreadTime,GPUTime,RenderThreadTime_CriticalPath,GameThreadTime_CriticalPath,RHIThreadTime,InputLatencyTime,MaxFrameTime,CPUUsage_Process,CPUUsage_Idle,Scheduler/GameThread/SignalStandbyThread,Scheduler/RenderThread/SignalStandbyThread,Scheduler/RHIInterruptThread/SignalStandbyThread,FMsgLogf/FMsgLogfCount
[HasHeaderRowAtEnd],1,[platform],Windows,[config],Development,[buildversion],++UE5+Release-5.5-CL-40574608,[engineversion],5.5.4-40574608+++UE5+Release-5.5,[os],Windows 11 (24H2) [10.0.26100.4061] ,[cpu],AuthenticAMD|AMD Ryzen 9 5900HX with Radeon Graphics,[pgoenabled],0,[pgoprofilingenabled],0,[ltoenabled],0,[asan],0,[loginid],9e9cf9e04c68c1fb7356bea0546b2101,[llm],0,[extradevelopmentmemorymb],0,[deviceprofile],WindowsEditor,[largeworldcoordinates],1,[streamingpoolsizemb],800,[raytracing],1,[csvid],45489AFF494E8037A8D3E8B88ACE5C5A,[targetframerate],165,[starttimestamp],1748095037,[namedevents],0,[endtimestamp],1748095037,[captureduration],0.22376,[commandline]," "E:\Unreal Projects\PipelineShowcase\PipelineShowcase.uproject""
    ```

    == 移动管线性能分析日志
    这是移动管线性能分析日志。```csv
EVENTS,Exclusive/AllWorkers/Effects,Exclusive/AllWorkers/Audio,Exclusive/AllWorkers/Physics,TextureStreaming/RenderAssetStreamingUpdate,TransientResourceCreateCount,TransientMemoryUsedMB,TransientMemoryAliasedMB,GPUMem/LocalBudgetMB,GPUMem/LocalUsedMB,GPUMem/SystemBudgetMB,GPUMem/SystemUsedMB,RHI/DrawCalls,RHI/PrimitivesDrawn,DrawCall/SlateUI,DrawCall/Basepass,DrawCall/CustomDepth,DrawCall/VirtualTextureUpdate,DrawCall/Prepass,DrawCall/Distortion,DrawCall/Fog,DrawCall/Lights,DrawCall/BeginOcclusionTests,DrawCall/ScreenSpaceReflections,DrawCall/ShadowDepths,DrawCall/SingleLayerWaterDepthPrepass,DrawCall/SingleLayerWater,DrawCall/Translucency,DrawCall/RenderVelocities,DrawCall/WaterInfoTexture,DrawCall/FXSystemPreInitViews,DrawCall/FXSystemPreRender,DrawCall/FXSystemPostRenderOpaque,Exclusive/AllWorkers/InitRenderResource,Exclusive/RenderThread/RenderThreadOther,Exclusive/RenderThread/EventWait,Exclusive/RenderThread/Material_UpdateDeferredCachedUniformExpressions,Exclusive/RenderThread/RemovePrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveInstances,Exclusive/RenderThread/ConsolidateInstanceDataAllocations,Exclusive/RenderThread/AddPrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveTransform,Exclusive/RenderThread/FPrimitiveSceneInfo_CacheMeshDrawCommands,Exclusive/RenderThread/FPrimitiveSceneInfo_CacheNaniteMaterialBins,Exclusive/RenderThread/PreRender,Exclusive/RenderThread/UpdateGPUScene,Exclusive/RenderThread/RenderOther,Exclusive/RenderThread/InitViews_Scene,Exclusive/RenderThread/Niagara,Exclusive/RenderThread/FetchVisibilityForPrimitives,Exclusive/RenderThread/InitViews_Shadows,Exclusive/RenderThread/ShadowInitDynamic,Exclusive/RenderThread/EventWait/Shadows,Exclusive/RenderThread/SortLights,Exclusive/RenderThread/ComputeLightGrid,Exclusive/RenderThread/LightFunctionAtlasGeneration,Exclusive/RenderThread/FXSystem,Exclusive/RenderThread/GPUSort,Exclusive/RenderThread/RenderShadows,Exclusive/RenderThread/RenderVelocities,Exclusive/RenderThread/RenderPostProcessing,Exclusive/RenderThread/RDG,Exclusive/RenderThread/STAT_RDG_FlushResourcesRHI,Exclusive/RenderThread/RDG_CollectResources,Exclusive/RenderThread/RDG_Execute,Exclusive/RenderThread/RenderPrePass,Exclusive/RenderThread/RenderBasePass,Exclusive/RenderThread/ViewExtensionPostRenderBasePass,Exclusive/RenderThread/RenderDecals,Exclusive/RenderThread/RenderTranslucency,Exclusive/RenderThread/PostRenderCleanUp,Exclusive/RenderThread/Slate,DrawSceneCommand_StartDelay,GPUSceneInstanceCount,LightCount/UpdatedShadowMaps,ShadowCacheUsageMB,PSO/PSOMisses,PSO/PSOMissesOnHitch,PSO/PSOPrevFrameMissesOnHitch,PSO/PSOComputeMisses,PSO/PSOComputeMissesOnHitch,PSO/PSOComputePrevFrameMissesOnHitch,RayTracingGeometry/TotalResidentSizeMB,RayTracingGeometry/TotalAlwaysResidentSizeMB,RenderTargetPool/UnusedMB,RenderTargetPool/PeakUsedMB,RenderTargetPoolSize,RenderTargetPoolUsed,RenderTargetPoolCount,RDGCount/Passes,RDGCount/Buffers,RDGCount/Textures,RenderThreadIdle/Total,RenderThreadIdle/CriticalPath,RenderThreadIdle/SwapBuffer,RenderThreadIdle/NonCriticalPath,RenderThreadIdle/GPUQuery,RenderTargetProfiler/ParticleCurveTexture,RenderTargetWasteProfiler/ParticleCurveTexture,RenderTargetProfiler/BackBuffer0,RenderTargetWasteProfiler/BackBuffer0,RenderTargetProfiler/BackBuffer1,RenderTargetWasteProfiler/BackBuffer1,RenderTargetProfiler/BackBuffer2,RenderTargetWasteProfiler/BackBuffer2,RenderTargetProfiler/FParticleStatePosition,RenderTargetWasteProfiler/FParticleStatePosition,RenderTargetProfiler/FParticleStateVelocity,RenderTargetWasteProfiler/FParticleStateVelocity,RenderTargetProfiler/FParticleAttributesTexture,RenderTargetWasteProfiler/FParticleAttributesTexture,RenderTargetProfiler/SSProfilePreIntegratedTexture,RenderTargetWasteProfiler/SSProfilePreIntegratedTexture,RenderTargetProfiler/MobileCSMAndSpotLightShadowmap,RenderTargetWasteProfiler/MobileCSMAndSpotLightShadowmap,RenderTargetProfiler/CombineLUTs,RenderTargetWasteProfiler/CombineLUTs,RenderTargetProfiler/ScreenSpaceAO,RenderTargetWasteProfiler/ScreenSpaceAO,RenderTargetProfiler/BloomSetup_EyeAdaptation,RenderTargetWasteProfiler/BloomSetup_EyeAdaptation,TextureProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureWasteProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureProfiler/T_Wall_Normal,TextureWasteProfiler/T_Wall_Normal,TextureProfiler/T_Poster,TextureWasteProfiler/T_Poster,TextureProfiler/T_st_exp,TextureWasteProfiler/T_st_exp,TextureProfiler/T_Book,TextureWasteProfiler/T_Book,TextureProfiler/T_Book_01,TextureWasteProfiler/T_Book_01,RenderTargetProfiler/Total,RenderTargetWasteProfiler/Total,RenderTargetProfiler/Other,RenderTargetWasteProfiler/Other,TextureProfiler/Total,TextureWasteProfiler/Total,TextureProfiler/Other,TextureWasteProfiler/Other,Exclusive/GameThread/Input,Exclusive/GameThread/EngineTickMisc,Exclusive/GameThread/AsyncLoading,Exclusive/GameThread/WorldTickMisc,Exclusive/GameThread/Effects,Exclusive/GameThread/NetworkIncoming,NavigationBuildDetailed/GameThread/Navigation_RebuildDirtyAreas,NavigationBuildDetailed/GameThread/Navigation_TickAsyncBuild,NavigationBuildDetailed/GameThread/Navigation_CrowdManager,Exclusive/GameThread/NavigationBuild,Exclusive/GameThread/ResetAsyncTraceTickTime,Exclusive/GameThread/WorldPreActorTick,Exclusive/GameThread/MovieSceneEval,Exclusive/GameThread/QueueTicks,Exclusive/GameThread/TickActors,Exclusive/GameThread/Animation,Exclusive/GameThread/Audio,Exclusive/GameThread/PlayerControllerTick,Exclusive/GameThread/Physics,Exclusive/GameThread/EventWait/EndPhysics,Exclusive/GameThread/SyncBodies,Exclusive/GameThread/FlushLatentActions,Exclusive/GameThread/TimerManager,Exclusive/GameThread/Tickables,Exclusive/GameThread/Landscape,Exclusive/GameThread/AIPerception,Exclusive/GameThread/EnvQueryManager,Exclusive/GameThread/Camera,Exclusive/GameThread/UpdateStreamingState,Exclusive/GameThread/RecordTickCountsToCSV,Exclusive/GameThread/RecordActorCountsToCSV,Exclusive/GameThread/ViewportMisc,Exclusive/GameThread/PostProcessSettings,Exclusive/GameThread/UpdateLevelStreaming,Exclusive/GameThread/EndOfFrameUpdates,Exclusive/GameThread/UI,Exclusive/GameThread/DebugHUD,Exclusive/GameThread/RenderAssetStreaming,Exclusive/GameThread/EventWait/RenderAssetStreaming,Slate/GameThread/TickPlatform,Slate/GameThread/DrawPrePass,Slate/GameThread/DrawWindows_Private,Exclusive/GameThread/DeferredTickTime,Exclusive/GameThread/CsvProfiler,Exclusive/GameThread/LLM,Exclusive/GameThread/EventWait,FileIO/QueuedPackagesQueueDepth,FileIO/ExistingQueuedPackagesQueueDepth,Basic/TicksQueued,ChaosPhysics/AABBTreeDirtyElementCount,ChaosPhysics/AABBTreeDirtyGridOverflowCount,ChaosPhysics/AABBTreeDirtyElementTooLargeCount,ChaosPhysics/AABBTreeDirtyElementNonEmptyCellCount,Ticks/ChaosDebugDrawComponent,Ticks/AbstractNavData,Ticks/RecastNavMesh,Ticks/SkeletalMeshComponent,Ticks/PlayerController,Ticks/LineBatchComponent,Ticks/HUD,Ticks/DefaultPawn,Ticks/FloatingPawnMovement,Ticks/FNiagaraWorldManagerTickFunction,Ticks/ParticleSystemManager,Ticks/FGameThreadAudioCommandQueue,Ticks/StartPhysicsTick,Ticks/EndPhysicsTick,Ticks/Total,ActorCount/Actor,ActorCount/RectLight,ActorCount/StaticMeshActor,ActorCount/TotalActorCount,LevelStreaming/NumLevelsPendingPurge,DynamicTranslucencyResolution,DynamicNaniteScalingShadow,DynamicNaniteScalingPrimary,View/PosX,View/PosY,View/PosZ,View/Speed,View/Speed2D,View/ForwardX,View/ForwardY,View/ForwardZ,View/UpX,View/UpY,View/UpZ,LevelStreamingProfiling/NumStreamingLevelsToConsider,TextureStreaming/StreamingPool,TextureStreaming/SafetyPool,TextureStreaming/TemporaryPool,TextureStreaming/CachedMips,TextureStreaming/WantedMips,TextureStreaming/ResidentMeshMem,TextureStreaming/StreamedMeshMem,TextureStreaming/NonStreamingMips,TextureStreaming/PendingStreamInData,IoDispatcher/PendingIoRequests,HttpManager/RequestsInQueue,HttpManager/MaxRequestsInQueue,HttpManager/RequestsInFlight,HttpManager/MaxRequestsInFlight,HttpManager/MaxTimeToWaitInQueue,HttpManager/DownloadedMB,HttpManager/BandwidthMbps,HttpManager/DurationMsAvg,AnimationParallelEvaluation/TotalTaskTime,AnimationParallelEvaluation/AverageTaskTime,AnimationParallelEvaluation/NumberOfTasks,AnimationParallelEvaluation/MinTaskTime,AnimationParallelEvaluation/MaxTaskTime,Shaders/ShaderMemoryMB,Shaders/NumShadersLoaded,Shaders/NumShaderMaps,Shaders/NumShadersCreated,Shaders/NumShaderMapsUsedForRendering,FrameTime,MemoryFreeMB,PhysicalUsedMB,VirtualUsedMB,ExtendedUsedMB,SystemMaxMB,RenderThreadTime,GameThreadTime,GPUTime,RenderThreadTime_CriticalPath,GameThreadTime_CriticalPath,RHIThreadTime,InputLatencyTime,MaxFrameTime,CPUUsage_Process,CPUUsage_Idle,Exclusive/RenderThread/InitRenderResource,CsvProfiler/NumTimestampsProcessed,CsvProfiler/NumCustomStatsProcessed,CsvProfiler/NumEventsProcessed,CsvProfiler/ProcessCSVStats,FMsgLogf/FMsgLogfCount
,0.080700,0.044800,0.1211,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0.5307,1.3268,0.003600,0.000400,0.000800,0.000700,0.000600,0.011300,0.014000,0.000100,0.032700,0.067800,0.1804,0.6183,0.009000,0.081800,0.099900,0.4116,0.036200,0.014300,0.044200,0.003600,0.011900,0.008800,0.2125,0.037600,0.1490,0.1870,0.028100,0.1189,0.1999,0.035300,0.1114,0.000700,0.023600,0.033600,0.001200,0.093300,0.016700,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,62,70,54,8.0179,6.9186,0.007000,1.0993,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.014500,0.091600,0.011300,0.1077,0.092900,0.001400,0.001600,0.001200,0.003400,0.010200,0.000900,0.005400,0.009000,0.014800,0.1237,0.091300,0.003700,0.060300,0.039000,0.1663,0.008500,0.000900,0.008600,0.068400,0.021700,0.001500,0.000500,0.026200,0.007600,0.016500,0.001200,0.1749,0.010000,0.000700,0.040100,0.2751,0.062200,0.042400,0.001900,0.084500,0.019000,0.037200,0.038900,0.005300,0.000100,0,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1134,0.1134,1,0.1134,0.1134,1.8285,2446,135,225,61,2.0033,6327.3164,3471.3867,4765.0430,0,9798.7031,3.6492,12.5443,3.0017,3.7711,12.5443,2.7734,21.1327,33.3333,0.081866,0.1681,0,0,0,0,0,0
,0.052200,0.043700,0.1496,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,958,6349801,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001400,0.3987,0.072700,0.005600,0.000400,0.001600,0.000600,0.000600,0.011300,0.011800,0.000100,0.024800,0.081100,0.1619,0.5673,0.010600,0.084900,0.1469,0.4060,0.025500,0.012700,0.037700,0.003200,0.009900,0.006600,0.1695,0.036300,0.1305,0.1552,0.029300,0.1056,0.2231,0.033500,0.078100,0.000600,0.019500,0.031500,0.000900,0.081600,1.9748,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.097600,0.097600,0.005400,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.008200,0.065100,0.008100,0.072400,0.045800,0.000500,0.001400,0.000700,0.002300,0.006900,0.000400,0.003100,0.006200,0.009500,0.062700,0.050400,0.001800,0.039800,0.054900,0.1668,0.007300,0.000600,0.001700,0.059300,0.097600,0.001000,0.000500,0.021500,0.007300,0.012700,0.000800,0.1120,0.009100,0.000800,0.034200,0.3366,0.058600,0.040500,0.001900,0.1606,0.020600,0.029200,0.043800,0.005200,0.000100,1.2680,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.072000,0.072000,1,0.072000,0.072000,1.8285,2446,135,225,61,2.9758,6327.3164,3471.3867,4765.0430,0,9798.7031,3.4854,1.6963,3.0017,10.4040,1.6963,2.7734,21.1327,33.3333,0.075881,0.2183,0,0,0,0,0,0
,0.072100,0.038000,0.1019,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,959,6349813,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001400,0.4150,0.1846,0.002100,0.000500,0.000900,0.000500,0.000400,0.012900,0.011500,0.000100,0.022900,0.052600,0.1702,0.7468,0.008900,0.1160,0.1456,0.4599,0.034300,0.033100,0.044500,0.003700,0.010500,0.007900,0.2169,0.037200,0.1359,0.1684,0.028800,0.1186,0.2205,0.032800,0.081700,0.000600,0.021000,0.032400,0.001100,0.089000,2.3345,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.2180,0.2180,0.005700,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.011300,0.077100,0.009500,0.063300,0.062900,0.000900,0.001200,0.000700,0.002900,0.008300,0.000400,0.004600,0.008100,0.011900,0.089800,0.069400,0.002700,0.062000,0.029000,0.069700,0.007800,0.000600,0.001800,0.058200,0.017000,0.001000,0.000500,0.018100,0.007200,0.012200,0.001500,0.1122,0.009200,0.000700,0.035200,0.2802,0.070300,0.048100,0.002700,0.1137,0.019400,0.026000,0.047300,0.006100,0,1.6501,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1321,0.1321,1,0.1321,0.1321,1.8285,2446,135,225,61,3.2471,6327.3164,3471.3867,4765.0430,0,9798.7031,3.1457,1.6012,3.0017,3.2433,1.6012,3.7209,20.1251,33.3333,0.084848,0.2364,0,0,0,0,0,0
,0.093100,0.052300,0.1361,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,942,6349789,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.002000,0.5267,0.1224,0.002100,0.000600,0.002400,0.000600,0.000700,0.022100,0.021000,0.000200,0.067100,0.068000,0.2044,0.6602,0.013100,0.088000,0.090500,0.3880,0.026000,0.013400,0.039000,0.002900,0.009300,0.007200,0.1730,0.037100,0.1347,0.1705,0.026800,0.1123,0.2088,0.032300,0.091600,0.000400,0.020100,0.032200,0.000900,0.090700,2.4821,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.1479,0.1479,0.005400,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.012500,0.094100,0.030700,0.085800,0.074000,0.000900,0.001300,0.000800,0.002600,0.008700,0.000300,0.003700,0.007700,0.011300,0.1176,0.075800,0.002400,0.052000,0.035600,0.1716,0.008400,0.000700,0.002600,0.093300,0.023800,0.002000,0.000800,0.033100,0.010000,0.016500,0.001300,0.1771,0.015000,0.001000,0.055900,0.4748,0.082600,0.038300,0.003600,0.2113,0.028400,0.036300,0.044500,0.005800,0.000100,1.5532,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.091100,0.091100,1,0.091100,0.091100,1.8285,2446,135,225,61,3.7319,6327.3164,3471.3867,4765.0430,0,9798.7031,3.5109,1.8626,3.0269,3.7289,1.8626,3.6347,20.1251,33.3333,0.089695,0.2039,0,0,0,0,0,0
,0.090200,0.051700,0.097900,0.076200,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,941,6349777,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001800,0.4982,0.2665,0.002300,0.000400,0.001200,0.000900,0.000400,0.013600,0.011100,0.000100,0.026100,0.058300,0.1893,0.7469,0.011100,0.1244,0.087000,0.4544,0.035000,0.015500,0.043400,0.003400,0.012400,0.009900,0.1992,0.038500,0.1641,0.1818,0.032800,0.1310,0.2084,0.037400,0.091000,0.000600,0.023900,0.035600,0.001200,0.1115,2.2924,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.3005,0.3005,0.006100,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.017300,0.090500,0.013300,0.1010,0.090700,0.001700,0.001500,0.001300,0.004600,0.013200,0.001200,0.006500,0.014900,0.018900,0.089500,0.1002,0.003800,0.075000,0.036500,0.1242,0.009400,0.000700,0.002200,0.083300,0.025200,0.001500,0.001000,0.029900,0.008000,0.014400,0.001300,0.1766,0.011100,0.001000,0.063000,0.2834,0.064600,0.037900,0.002000,0.097300,0.019200,0.038400,0.052000,0.006900,0,1.6069,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1162,0.1162,1,0.1162,0.1162,1.8285,2446,135,225,61,3.5926,6327.3164,3471.3867,4765.0430,0,9798.7031,3.4199,2.2116,3.4685,3.5678,2.2116,3.3183,20.1251,33.3333,0.089818,0.1981,0,0,0,0,0,0
,0.1243,0.060600,0.1723,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,945,6349825,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001800,0.6595,0.2586,0.002600,0.000500,0.001200,0.000600,0.000800,0.013200,0.014200,0.000100,0.032400,0.065300,0.1836,0.7376,0.012800,0.1505,0.1566,0.4411,0.018400,0.014300,0.047300,0.003600,0.013900,0.013800,0.2532,0.049700,0.6302,0.3510,0.029300,0.1627,0.4367,0.3838,0.2230,0.002200,0.037500,0.1379,0.002000,0.1041,2.6646,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.2759,0.2759,0.1610,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.013500,0.096600,0.009900,0.090000,0.084400,0.000900,0.001700,0.000800,0.003100,0.009200,0.000500,0.004600,0.009100,0.012000,0.1526,0.084200,0.003200,0.065800,0.034200,0.1461,0.008400,0.000700,0.002100,0.079900,0.023300,0.002200,0.001300,0.033000,0.010000,0.018900,0.001100,0.1520,0.011500,0.000900,0.060200,0.4101,0.091800,0.062100,0.002400,0.1382,0.025400,0.032400,0.084600,0.008100,0.000100,1.7526,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1235,0.1235,1,0.1235,0.1235,1.8285,2446,135,225,61,3.9718,6327.3633,3471.3867,4765.0430,0,9798.7031,3.6273,1.9924,2.9782,3.9278,1.9924,3.6301,20.1251,33.3333,0.095283,0.1864,0.001900,1512,851,0,0.5875,0
,0.1174,0.049000,0.1422,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,947,6349853,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0,0.5344,0.6048,0.002000,0.000600,0.001000,0.000800,0.000800,0.011900,0.013400,0.000100,0.026800,0.071200,0.2929,0.6821,0.010900,0.1487,0.097500,0.6491,0.034300,0.024100,0.064100,0.005300,0.012800,0.010600,0.2981,0.045900,0.2057,0.1991,0.032400,0.1271,0.2292,0.061200,0.090500,0.001000,0.025900,0.035200,0.001400,0.1086,4.3965,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.6381,0.6381,0.007400,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.016000,0.1250,0.011000,0.087200,0.1020,0.001400,0.002300,0.001300,0.004100,0.012000,0.001100,0.005500,0.010300,0.014300,0.098300,0.1384,0.003900,0.078900,0.047600,0.1794,0.008300,0.000400,0.001600,0.063200,0.021300,0.001500,0.000600,0.027500,0.009800,0.011700,0.001000,0.1759,0.011600,0.001300,0.062300,0.3265,0.084900,0.048300,0.001800,0.1080,0.021200,0.028500,0.066800,0.005800,0,3.5200,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1402,0.1402,1,0.1402,0.1402,1.8285,2446,135,225,61,5.6976,6327.3633,3471.3867,4765.0430,0,9798.7500,5.2870,2.2597,3.4143,5.5629,2.2597,3.4479,20.1251,33.3333,0.076351,0.2022,0,0,0,0,0,0
,0.091500,0.044900,0.1450,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,946,6349841,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001600,0.4728,0.1735,0.002200,0.000400,0.001000,0.000800,0.000400,0.011700,0.012800,0.000200,0.026400,0.056700,0.1744,0.6333,0.010400,0.089700,0.1234,0.4076,0.026200,0.014200,0.040900,0.003200,0.010200,0.007600,0.1814,0.045500,0.1669,0.1791,0.026600,0.1139,0.2296,0.033900,0.082500,0.000600,0.020700,0.033200,0.001200,0.091900,3.6487,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.1987,0.1987,0.005500,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.015100,0.075600,0.009500,0.079800,0.082300,0.001200,0.001600,0.000900,0.002600,0.008700,0.000700,0.004300,0.008200,0.049700,0.097300,0.086600,0.003200,0.060000,0.036700,0.1785,0.008400,0.000500,0.002100,0.069000,0.019100,0.001100,0.000400,0.024300,0.009400,0.014400,0.001100,0.1733,0.011300,0.001200,0.041900,0.3071,0.082600,0.045500,0.001800,0.1082,0.021300,0.030200,0.052700,0.007100,0.000600,2.8453,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1115,0.1115,1,0.1115,0.1115,1.8285,2446,135,225,61,4.8195,6327.3633,3471.3867,4765.0430,0,9798.7500,4.1790,2.0813,2.8911,4.8171,2.0813,3.3264,20.1251,33.3333,0.068875,0.2006,0,0,0,0,0,0
,0.081200,0.044300,0.1222,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,938,6349745,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001400,0.4263,0.1786,0.002600,0.000600,0.001400,0.000500,0.000500,0.012500,0.013600,0.000200,0.026700,0.060300,0.2083,0.6603,0.010200,0.090800,0.1509,0.4012,0.033300,0.015100,0.046300,0.003400,0.010700,0.009700,0.1808,0.046400,0.1491,0.1655,0.027600,0.1178,0.2379,0.035100,0.085300,0.000700,0.020000,0.033200,0.001100,0.087500,2.4299,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.2111,0.2111,0.007500,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.014000,0.1002,0.009100,0.076900,0.077600,0.001000,0.001300,0.000800,0.002800,0.008600,0.000500,0.004100,0.007900,0.012300,0.088500,0.078900,0.002800,0.057500,0.034900,0.1517,0.007400,0.000600,0.001700,0.063100,0.018600,0.001400,0.000500,0.029000,0.008700,0.013800,0.001200,0.1575,0.017700,0.001200,0.046200,0.2935,0.080100,0.040500,0.002100,0.1046,0.019700,0.028600,0.046500,0.005200,0,1.6899,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1129,0.1129,1,0.1129,0.1129,1.8285,2446,135,225,61,3.5684,6327.3633,3471.3867,4765.0430,0,9798.7500,3.3896,1.9023,2.8911,3.5883,1.9023,3.9099,16.2060,33.3333,0.085347,0.2254,0,0,0,0,0,0
,0.072400,0.074400,0.1845,0,0,128,30.5000,15409,1400.3867,13502.1543,122.2578,949,6349877,6,190,0,0,153,0,0,0,0,0,187,0,0,125,32,0,0,0,0,0.001700,0.4259,0.1682,0.002000,0.000500,0.001300,0.000600,0.000400,0.011700,0.013100,0.000100,0.024500,0.056200,0.1779,0.5705,0.009900,0.1057,0.091400,0.4618,0,0.013000,0.040800,0.003500,0.011800,0.008400,0.1929,0.041800,0.1426,0.2091,0.026900,0.1182,0.2295,0.040400,0.094700,0.001000,0.027700,0.035100,0.001300,0.1340,2.2993,3952,0,0,0,-1,-1,0,-1,-1,0,0,0,32.9805,32.9805,32.9805,9,64,70,54,0.1675,0.1675,0.005200,0,0,1,0,4,0,4,0,4,0,32,0,16,0,8,0,1,0,32,0,1,0,1,0,1,0,17,0,22,0,16,0,43,0,295,0,373,0,102,0,0,0,888,0,125,0,0.016200,0.093600,0.011700,0.080100,0.1037,0.000900,0.001300,0.000900,0.003400,0.009200,0.000700,0.004700,0.008300,0.013100,0.1006,0.083700,0.003600,0.071500,0.051100,0.2196,0.010000,0.000800,0.002300,0.080700,0.024100,0.001300,0.000600,0.022500,0.007200,0.013200,0.001400,0.1726,0.014800,0.001200,0.056300,0.3106,0.067500,0.040000,0.002300,0.097000,0.031000,0.030700,0.051600,0.061400,0,1.5547,0,0,28,0,0,0,0,1,1,1,1,1,3,1,1,1,7,7,1,1,1,28,89,7,233,360,0,-100,-100,-100,-150,50,92,0,0,-0.5000,-0.8660,0,0,0,1,0,76.9922,5,50,0.5156,76.9922,0,0,810.1641,0,0,0,0,0,0,0,0,0,0,0.1020,0.1020,1,0.1020,0.1020,1.8285,2446,135,225,61,3.6870,6327.3633,3471.3867,4765.0430,0,9798.7500,3.4000,2.0423,2.9136,3.6111,2.0423,3.4396,16.2060,33.3333,0.091714,0.2094,0.001900,0,0,0,0,2
EVENTS,Exclusive/AllWorkers/Effects,Exclusive/AllWorkers/Audio,Exclusive/AllWorkers/Physics,TextureStreaming/RenderAssetStreamingUpdate,TransientResourceCreateCount,TransientMemoryUsedMB,TransientMemoryAliasedMB,GPUMem/LocalBudgetMB,GPUMem/LocalUsedMB,GPUMem/SystemBudgetMB,GPUMem/SystemUsedMB,RHI/DrawCalls,RHI/PrimitivesDrawn,DrawCall/SlateUI,DrawCall/Basepass,DrawCall/CustomDepth,DrawCall/VirtualTextureUpdate,DrawCall/Prepass,DrawCall/Distortion,DrawCall/Fog,DrawCall/Lights,DrawCall/BeginOcclusionTests,DrawCall/ScreenSpaceReflections,DrawCall/ShadowDepths,DrawCall/SingleLayerWaterDepthPrepass,DrawCall/SingleLayerWater,DrawCall/Translucency,DrawCall/RenderVelocities,DrawCall/WaterInfoTexture,DrawCall/FXSystemPreInitViews,DrawCall/FXSystemPreRender,DrawCall/FXSystemPostRenderOpaque,Exclusive/AllWorkers/InitRenderResource,Exclusive/RenderThread/RenderThreadOther,Exclusive/RenderThread/EventWait,Exclusive/RenderThread/Material_UpdateDeferredCachedUniformExpressions,Exclusive/RenderThread/RemovePrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveInstances,Exclusive/RenderThread/ConsolidateInstanceDataAllocations,Exclusive/RenderThread/AddPrimitiveSceneInfos,Exclusive/RenderThread/UpdatePrimitiveTransform,Exclusive/RenderThread/FPrimitiveSceneInfo_CacheMeshDrawCommands,Exclusive/RenderThread/FPrimitiveSceneInfo_CacheNaniteMaterialBins,Exclusive/RenderThread/PreRender,Exclusive/RenderThread/UpdateGPUScene,Exclusive/RenderThread/RenderOther,Exclusive/RenderThread/InitViews_Scene,Exclusive/RenderThread/Niagara,Exclusive/RenderThread/FetchVisibilityForPrimitives,Exclusive/RenderThread/InitViews_Shadows,Exclusive/RenderThread/ShadowInitDynamic,Exclusive/RenderThread/EventWait/Shadows,Exclusive/RenderThread/SortLights,Exclusive/RenderThread/ComputeLightGrid,Exclusive/RenderThread/LightFunctionAtlasGeneration,Exclusive/RenderThread/FXSystem,Exclusive/RenderThread/GPUSort,Exclusive/RenderThread/RenderShadows,Exclusive/RenderThread/RenderVelocities,Exclusive/RenderThread/RenderPostProcessing,Exclusive/RenderThread/RDG,Exclusive/RenderThread/STAT_RDG_FlushResourcesRHI,Exclusive/RenderThread/RDG_CollectResources,Exclusive/RenderThread/RDG_Execute,Exclusive/RenderThread/RenderPrePass,Exclusive/RenderThread/RenderBasePass,Exclusive/RenderThread/ViewExtensionPostRenderBasePass,Exclusive/RenderThread/RenderDecals,Exclusive/RenderThread/RenderTranslucency,Exclusive/RenderThread/PostRenderCleanUp,Exclusive/RenderThread/Slate,DrawSceneCommand_StartDelay,GPUSceneInstanceCount,LightCount/UpdatedShadowMaps,ShadowCacheUsageMB,PSO/PSOMisses,PSO/PSOMissesOnHitch,PSO/PSOPrevFrameMissesOnHitch,PSO/PSOComputeMisses,PSO/PSOComputeMissesOnHitch,PSO/PSOComputePrevFrameMissesOnHitch,RayTracingGeometry/TotalResidentSizeMB,RayTracingGeometry/TotalAlwaysResidentSizeMB,RenderTargetPool/UnusedMB,RenderTargetPool/PeakUsedMB,RenderTargetPoolSize,RenderTargetPoolUsed,RenderTargetPoolCount,RDGCount/Passes,RDGCount/Buffers,RDGCount/Textures,RenderThreadIdle/Total,RenderThreadIdle/CriticalPath,RenderThreadIdle/SwapBuffer,RenderThreadIdle/NonCriticalPath,RenderThreadIdle/GPUQuery,RenderTargetProfiler/ParticleCurveTexture,RenderTargetWasteProfiler/ParticleCurveTexture,RenderTargetProfiler/BackBuffer0,RenderTargetWasteProfiler/BackBuffer0,RenderTargetProfiler/BackBuffer1,RenderTargetWasteProfiler/BackBuffer1,RenderTargetProfiler/BackBuffer2,RenderTargetWasteProfiler/BackBuffer2,RenderTargetProfiler/FParticleStatePosition,RenderTargetWasteProfiler/FParticleStatePosition,RenderTargetProfiler/FParticleStateVelocity,RenderTargetWasteProfiler/FParticleStateVelocity,RenderTargetProfiler/FParticleAttributesTexture,RenderTargetWasteProfiler/FParticleAttributesTexture,RenderTargetProfiler/SSProfilePreIntegratedTexture,RenderTargetWasteProfiler/SSProfilePreIntegratedTexture,RenderTargetProfiler/MobileCSMAndSpotLightShadowmap,RenderTargetWasteProfiler/MobileCSMAndSpotLightShadowmap,RenderTargetProfiler/CombineLUTs,RenderTargetWasteProfiler/CombineLUTs,RenderTargetProfiler/ScreenSpaceAO,RenderTargetWasteProfiler/ScreenSpaceAO,RenderTargetProfiler/BloomSetup_EyeAdaptation,RenderTargetWasteProfiler/BloomSetup_EyeAdaptation,TextureProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureWasteProfiler//Engine/MapTemplates/Sky/DaylightAmbientCubemap.DaylightAmbientCubemap,TextureProfiler/T_Wall_Normal,TextureWasteProfiler/T_Wall_Normal,TextureProfiler/T_Poster,TextureWasteProfiler/T_Poster,TextureProfiler/T_st_exp,TextureWasteProfiler/T_st_exp,TextureProfiler/T_Book,TextureWasteProfiler/T_Book,TextureProfiler/T_Book_01,TextureWasteProfiler/T_Book_01,RenderTargetProfiler/Total,RenderTargetWasteProfiler/Total,RenderTargetProfiler/Other,RenderTargetWasteProfiler/Other,TextureProfiler/Total,TextureWasteProfiler/Total,TextureProfiler/Other,TextureWasteProfiler/Other,Exclusive/GameThread/Input,Exclusive/GameThread/EngineTickMisc,Exclusive/GameThread/AsyncLoading,Exclusive/GameThread/WorldTickMisc,Exclusive/GameThread/Effects,Exclusive/GameThread/NetworkIncoming,NavigationBuildDetailed/GameThread/Navigation_RebuildDirtyAreas,NavigationBuildDetailed/GameThread/Navigation_TickAsyncBuild,NavigationBuildDetailed/GameThread/Navigation_CrowdManager,Exclusive/GameThread/NavigationBuild,Exclusive/GameThread/ResetAsyncTraceTickTime,Exclusive/GameThread/WorldPreActorTick,Exclusive/GameThread/MovieSceneEval,Exclusive/GameThread/QueueTicks,Exclusive/GameThread/TickActors,Exclusive/GameThread/Animation,Exclusive/GameThread/Audio,Exclusive/GameThread/PlayerControllerTick,Exclusive/GameThread/Physics,Exclusive/GameThread/EventWait/EndPhysics,Exclusive/GameThread/SyncBodies,Exclusive/GameThread/FlushLatentActions,Exclusive/GameThread/TimerManager,Exclusive/GameThread/Tickables,Exclusive/GameThread/Landscape,Exclusive/GameThread/AIPerception,Exclusive/GameThread/EnvQueryManager,Exclusive/GameThread/Camera,Exclusive/GameThread/UpdateStreamingState,Exclusive/GameThread/RecordTickCountsToCSV,Exclusive/GameThread/RecordActorCountsToCSV,Exclusive/GameThread/ViewportMisc,Exclusive/GameThread/PostProcessSettings,Exclusive/GameThread/UpdateLevelStreaming,Exclusive/GameThread/EndOfFrameUpdates,Exclusive/GameThread/UI,Exclusive/GameThread/DebugHUD,Exclusive/GameThread/RenderAssetStreaming,Exclusive/GameThread/EventWait/RenderAssetStreaming,Slate/GameThread/TickPlatform,Slate/GameThread/DrawPrePass,Slate/GameThread/DrawWindows_Private,Exclusive/GameThread/DeferredTickTime,Exclusive/GameThread/CsvProfiler,Exclusive/GameThread/LLM,Exclusive/GameThread/EventWait,FileIO/QueuedPackagesQueueDepth,FileIO/ExistingQueuedPackagesQueueDepth,Basic/TicksQueued,ChaosPhysics/AABBTreeDirtyElementCount,ChaosPhysics/AABBTreeDirtyGridOverflowCount,ChaosPhysics/AABBTreeDirtyElementTooLargeCount,ChaosPhysics/AABBTreeDirtyElementNonEmptyCellCount,Ticks/ChaosDebugDrawComponent,Ticks/AbstractNavData,Ticks/RecastNavMesh,Ticks/SkeletalMeshComponent,Ticks/PlayerController,Ticks/LineBatchComponent,Ticks/HUD,Ticks/DefaultPawn,Ticks/FloatingPawnMovement,Ticks/FNiagaraWorldManagerTickFunction,Ticks/ParticleSystemManager,Ticks/FGameThreadAudioCommandQueue,Ticks/StartPhysicsTick,Ticks/EndPhysicsTick,Ticks/Total,ActorCount/Actor,ActorCount/RectLight,ActorCount/StaticMeshActor,ActorCount/TotalActorCount,LevelStreaming/NumLevelsPendingPurge,DynamicTranslucencyResolution,DynamicNaniteScalingShadow,DynamicNaniteScalingPrimary,View/PosX,View/PosY,View/PosZ,View/Speed,View/Speed2D,View/ForwardX,View/ForwardY,View/ForwardZ,View/UpX,View/UpY,View/UpZ,LevelStreamingProfiling/NumStreamingLevelsToConsider,TextureStreaming/StreamingPool,TextureStreaming/SafetyPool,TextureStreaming/TemporaryPool,TextureStreaming/CachedMips,TextureStreaming/WantedMips,TextureStreaming/ResidentMeshMem,TextureStreaming/StreamedMeshMem,TextureStreaming/NonStreamingMips,TextureStreaming/PendingStreamInData,IoDispatcher/PendingIoRequests,HttpManager/RequestsInQueue,HttpManager/MaxRequestsInQueue,HttpManager/RequestsInFlight,HttpManager/MaxRequestsInFlight,HttpManager/MaxTimeToWaitInQueue,HttpManager/DownloadedMB,HttpManager/BandwidthMbps,HttpManager/DurationMsAvg,AnimationParallelEvaluation/TotalTaskTime,AnimationParallelEvaluation/AverageTaskTime,AnimationParallelEvaluation/NumberOfTasks,AnimationParallelEvaluation/MinTaskTime,AnimationParallelEvaluation/MaxTaskTime,Shaders/ShaderMemoryMB,Shaders/NumShadersLoaded,Shaders/NumShaderMaps,Shaders/NumShadersCreated,Shaders/NumShaderMapsUsedForRendering,FrameTime,MemoryFreeMB,PhysicalUsedMB,VirtualUsedMB,ExtendedUsedMB,SystemMaxMB,RenderThreadTime,GameThreadTime,GPUTime,RenderThreadTime_CriticalPath,GameThreadTime_CriticalPath,RHIThreadTime,InputLatencyTime,MaxFrameTime,CPUUsage_Process,CPUUsage_Idle,Exclusive/RenderThread/InitRenderResource,CsvProfiler/NumTimestampsProcessed,CsvProfiler/NumCustomStatsProcessed,CsvProfiler/NumEventsProcessed,CsvProfiler/ProcessCSVStats,FMsgLogf/FMsgLogfCount
[HasHeaderRowAtEnd],1,[platform],Windows,[config],Development,[buildversion],++UE5+Release-5.5-CL-40574608,[engineversion],5.5.4-40574608+++UE5+Release-5.5,[os],Windows 11 (24H2) [10.0.26100.4061] ,[cpu],AuthenticAMD|AMD Ryzen 9 5900HX with Radeon Graphics,[pgoenabled],0,[pgoprofilingenabled],0,[ltoenabled],0,[asan],0,[loginid],9e9cf9e04c68c1fb7356bea0546b2101,[llm],0,[extradevelopmentmemorymb],0,[deviceprofile],WindowsEditor,[largeworldcoordinates],1,[streamingpoolsizemb],1000,[raytracing],0,[csvid],CCBDA2484DFC60896A860FB72C472C34,[targetframerate],165,[starttimestamp],1748095359,[namedevents],0,[endtimestamp],1748095359,[captureduration],0.037215,[commandline]," "../../../../../../Unreal Projects/PipelineShowcase/PipelineShowcase.uproject" /Game/Show/Map_Day_Mobile -game -PIEVIACONSOLE -Multiprocess GameUserSettingsINI=PIEGameUserSettings0 -MultiprocessSaveConfig -forcepassthrough -messaging -SessionName="Play in Standalone Game" -featureleveles31 -faketouches -MultiprocessSaveConfig -windowed -WinX=640 -WinY=372 SAVEWINPOS=1 -ResX=1280 -ResY=720"
    ```
    = 输入数据处理脚本
    附录A的csv文件可被虚幻引擎自带分析工具解析和处理。输入数据由额外模块抓取，因此需要自行编写处理脚本。脚本如下：
    ```python
import pandas as pd
import numpy as np
from scipy import stats
import os
# --- Configuration ---
# Path for the controller data (assuming it's the file you showed snippets from)
controller_file_path = "ControllerInput.csv" # Or "input_file_0.csv" if that's the actual name

# Path for the keyboard data - YOU MUST UPDATE THIS
keyboard_file_path = "KeyboardInput.csv" # <<< IMPORTANT: UPDATE THIS PATH to your keyboard log data file

ARTIFACT_LATENCY_THRESHOLD_MS = 500 # Latencies above this on a suspected segment reset line will be filtered (e.g., 500ms)
RESET_DROP_SECONDS = 0.5 # Absolute drop in input_ts to suspect a reset
RESET_FACTOR = 0.5       # Relative drop in input_ts to suspect a reset (e.g., current < previous * 0.5)

equivalence_delta = 3.0 # Equivalence margin in ms for TOST
alpha = 0.05 # Significance level

report_sections = []
filtered_counts = {"controller": 0, "keyboard": 0}

def add_to_report(title, content):
    report_sections.append(f"\n--- {title} ---\n{content}")

def parse_latency_log_file(filepath, device_name):
    latencies_ms = []
    previous_input_ts = None
    processed_lines = 0
    valid_latency_lines = 0

    if not os.path.exists(filepath):
        add_to_report(f"错误 - {device_name} 数据文件未找到", f"文件路径 '{filepath}' 无效或文件不存在。")
        return pd.Series([], dtype=float)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for i, line in enumerate(f):
                processed_lines += 1
                try:
                    if "LATENCY_LOG," in line:
                        parts = line.split("LATENCY_LOG,")
                        if len(parts) > 1:
                            data_part = parts[1].strip()
                            values = data_part.split(',')
                            # Expected: Operation, InputTS, ResponseTS, LatencyDuration
                            if len(values) == 4 and values[0].strip().lower() == "move":
                                op_type = values[0].strip()
                                current_input_ts = float(values[1].strip())
                                response_ts = float(values[2].strip()) # Now used for filtering
                                latency_s = float(values[3].strip())

                                # Sanity check (optional, but good for understanding logs)
                                # calculated_latency_s = abs(response_ts - current_input_ts)
                                # if abs(calculated_latency_s - latency_s) > 0.001 : # epsilon
                                #     print(f"Warning ({device_name}): Line {i+1}: Discrepancy in calculated latency. Provided: {latency_s:.3f}, Calc: {calculated_latency_s:.3f}")

                                potential_artifact = False
                                
                                # Check Condition 1: InputTS sequence reset
                                if previous_input_ts is not None:
                                    if current_input_ts < previous_input_ts * RESET_FACTOR and \
                                       (previous_input_ts - current_input_ts) > RESET_DROP_SECONDS:
                                        if (latency_s * 1000) > ARTIFACT_LATENCY_THRESHOLD_MS:
                                            potential_artifact = True
                                            # Optional: print(f"Debug ({device_name}): Line {i+1}: Potential artifact (type 1: InputTS sequence reset) {latency_s*1000:.2f}ms. PrevInputTS: {previous_input_ts:.3f}, CurrInputTS: {current_input_ts:.3f}")

                                # Check Condition 2: Intra-line reset (ResponseTS <= InputTS), only if not already flagged
                                if not potential_artifact: 
                                    if response_ts <= current_input_ts: # Changed to '<=' and removed inner latency check
                                        potential_artifact = True
                                        # Optional: print(f"Debug ({device_name}): Line {i+1}: Potential artifact (type 2: Intra-line reset RspTS <= InpTS). InputTS: {current_input_ts:.3f}, RspTS: {response_ts:.3f}, Latency: {latency_s*1000:.2f}ms")
                                
                                # Final decision based on whether any check flagged it as an artifact
                                if potential_artifact:
                                     filtered_counts[device_name.lower()] += 1
                                else:
                                    latencies_ms.append(latency_s * 1000) # Convert to ms
                                    valid_latency_lines +=1
                                
                                previous_input_ts = current_input_ts
                except ValueError:
                    # print(f"Warning ({device_name}): Could not parse numeric value from line {i+1}: {line.strip()}")
                    pass # Silently skip lines with parsing errors for numeric values
                except Exception as e_line:
                    # print(f"Warning ({device_name}): Error processing line {i+1} '{line.strip()}': {e_line}")
                    pass
    except Exception as e_file:
        add_to_report(f"错误 - 读取或解析 {device_name} 文件时出错",
                      f"处理文件 '{filepath}' 时发生错误: {e_file}")
        return pd.Series([], dtype=float)

    if not latencies_ms:
        add_to_report(f"警告 - {device_name} 数据提取",
                      f"未能从文件 '{filepath}' 中提取任何有效的 'Move' 操作延迟数据 (after filtering).\n"
                      f"Processed lines: {processed_lines}. Valid latency lines added: {valid_latency_lines}. Filtered artifacts: {filtered_counts[device_name.lower()]}.\n"
                      f"确保文件包含 'LATENCY_LOG,Move,InputTS,ResponseTS,LatencyValue' 格式的行。")
    return pd.Series(latencies_ms, dtype=float)


def describe_data(series, name):
    # (Function remains the same as your provided working version)
    if series.empty or len(series) < 2 :
        return (f"  有效条目数: {len(series)}\n"
                f"  数据不足，无法计算完整的描述性统计。")
    # ... (rest of the describe_data function as in your provided output script) ...
    q1 = series.quantile(0.25)
    q3 = series.quantile(0.75)
    median = series.median()
    cv = (series.std() / series.mean()) * 100 if series.mean() != 0 else 0
    iqr = q3 - q1
    # Handle cases where IQR might be 0 to avoid division by zero or nonsensical bounds
    if iqr == 0:
        # If IQR is 0, outlier bounds are typically Q1 and Q3 themselves.
        # For this specific case, we'll define bounds that are slightly offset if Q1=Q3
        # or simply state that any deviation is an outlier.
        # Given the previous output, this method makes sense.
        lower_bound_outlier = q1 
        upper_bound_outlier = q3
        if q1 == q3:
             outlier_desc = f"any value != {q1:.2f} ms (since Q1=Q3)"
        else:
             outlier_desc = f"< {lower_bound_outlier:.2f} ms or > {upper_bound_outlier:.2f} ms (IQR=0)"

    else:
        lower_bound_outlier = q1 - 1.5 * iqr
        upper_bound_outlier = q3 + 1.5 * iqr
        outlier_desc = f"< {lower_bound_outlier:.2f} ms or > {upper_bound_outlier:.2f} ms (1.5*IQR rule)"

    outliers = series[(series < lower_bound_outlier) | (series > upper_bound_outlier)]
    # Specific fix for when Q1=Q3, then outliers are anything not equal to Q1/Q3
    if q1 == q3:
        outliers = series[series != q1]


    return (
        f"  有效条目数: {len(series)}\n"
        f"  平均延迟: {series.mean():.2f} ms\n"
        f"  中位数延迟: {median:.2f} ms\n"
        f"  标准差: {series.std():.2f} ms\n"
        f"  最小延迟: {series.min():.2f} ms\n"
        f"  最大延迟: {series.max():.2f} ms\n"
        f"  25百分位数 (Q1): {q1:.2f} ms\n"
        f"  75百分位数 (Q3): {q3:.2f} ms\n"
        f"  四分位数间距 (IQR): {iqr:.2f} ms\n"
        f"  变异系数 (CV): {cv:.2f}% (越低越稳定)\n"
        f"  离群点识别界限: {outlier_desc}\n"
        f"  识别出的潜在离群点数量: {len(outliers)} (示例值: {list(np.unique(outliers.values[:5])) if not outliers.empty else 'N/A'}{'...' if len(np.unique(outliers.values)) > 5 else ''})"
    )

# --- Main script execution ---
try:
    add_to_report("数据加载与预处理",
                  f"尝试从以下路径加载、解析和过滤数据:\n"
                  f"  手柄: {controller_file_path}\n"
                  f"  键盘: {keyboard_file_path} (请确保此路径正确并指向格式相似的文件)\n"
                  f"潜在的跨段伪影延迟值 (InputTS重置时 > {ARTIFACT_LATENCY_THRESHOLD_MS}ms) 将被过滤。")

    controller_latency = parse_latency_log_file(controller_file_path, "Controller")
    keyboard_latency = parse_latency_log_file(keyboard_file_path, "Keyboard")

    add_to_report("预处理总结 - 伪影过滤",
                  f"  手柄: {filtered_counts['controller']} 个潜在的伪影延迟值被过滤。\n"
                  f"  键盘: {filtered_counts['keyboard']} 个潜在的伪影延迟值被过滤。")

    if controller_latency.empty:
        add_to_report("手柄数据问题", "未能从手柄数据文件中加载任何有效延迟数据。后续分析可能不完整或失败。")
    if keyboard_latency.empty:
        add_to_report("键盘数据问题", "未能从键盘数据文件中加载任何有效延迟数据。后续分析可能不完整或失败。")

    # --- Descriptive Statistics ---
    add_to_report("手柄输入 描述性统计 (过滤后)", describe_data(controller_latency, "手柄"))
    add_to_report("键盘输入 描述性统计 (过滤后)", describe_data(keyboard_latency, "键盘"))

    if len(controller_latency) < 20 or len(keyboard_latency) < 20: # Increased threshold for meaningful analysis
        add_to_report("分析警示", "一个或两个数据集的数据量较少 (少于20个有效条目)。统计结果的可靠性可能较低。")
        if len(controller_latency) < 2 or len(keyboard_latency) < 2:
             raise ValueError("数据不足，无法进行完整的推断性统计分析。")


    # --- Assumption Checking for t-test ---
    # Shapiro-Wilk test might be slow/unreliable for very large N, but let's keep it as per previous script
    shapiro_controller_stat, shapiro_controller_p = stats.shapiro(controller_latency) if len(controller_latency) < 5000 else (np.nan, np.nan)
    shapiro_keyboard_stat, shapiro_keyboard_p = stats.shapiro(keyboard_latency) if len(keyboard_latency) < 5000 else (np.nan, np.nan)
    normality_note = "(注: p < {alpha} 表明数据显著偏离正态分布。对于大样本(N > ~50)，此检验非常敏感；对于N>5000，已跳过检验。建议结合直方图/QQ图判断。)" if len(controller_latency) >=5000 or len(keyboard_latency) >=5000 else "(注: p < {alpha} 表明数据显著偏离正态分布。对于大样本(N > ~50)，此检验非常敏感。)"
    normality_report = (
        f"  手柄 - Shapiro-Wilk: W={shapiro_controller_stat:.4f}, p={shapiro_controller_p:.4e} "
        f"({'不满足正态性' if shapiro_controller_p < alpha else '近似正态分布' if not np.isnan(shapiro_controller_p) else '跳过 (N>5000)'})\n"
        f"  键盘 - Shapiro-Wilk: W={shapiro_keyboard_stat:.4f}, p={shapiro_keyboard_p:.4e} "
        f"({'不满足正态性' if shapiro_keyboard_p < alpha else '近似正态分布' if not np.isnan(shapiro_keyboard_p) else '跳过 (N>5000)'})\n"
        f"{normality_note}"
    )
    add_to_report("正态性检验 (Shapiro-Wilk)", normality_report)

    levene_stat, levene_p = stats.levene(controller_latency, keyboard_latency)
    homogeneity_report = (
        f"  Levene's Test: W={levene_stat:.4f}, p={levene_p:.4e} "
        f"({'方差不齐性' if levene_p < alpha else '满足方差齐性'})\n"
        f"(注: p < {alpha} 表明两组方差不相等)"
    )
    add_to_report("方差齐性检验 (Levene's Test)", homogeneity_report)

    # --- Inferential Statistics ---
    inferential_results = []
    equal_var_flag = levene_p >= alpha
    t_stat, t_p_value = stats.ttest_ind(controller_latency, keyboard_latency, equal_var=equal_var_flag, nan_policy='omit')
    inferential_results.append(
        f"  独立样本 t-检验 (equal_var={equal_var_flag}):\n"
        f"    t-statistic = {t_stat:.3f}\n"
        f"    p-value = {t_p_value:.4e}\n"
        f"    解释: {'差异不显著' if t_p_value >= alpha else '均值存在显著差异'} (p {'<' if t_p_value < alpha else '>='} {alpha})"
    )

    u_stat, u_p_value = stats.mannwhitneyu(controller_latency, keyboard_latency, alternative='two-sided', nan_policy='omit')
    inferential_results.append(
        f"\n  Mann-Whitney U 检验:\n"
        f"    U-statistic = {u_stat:.1f}\n"
        f"    p-value = {u_p_value:.4e}\n"
        f"    解释: {'分布无显著差异' if u_p_value >= alpha else '分布存在显著差异'} (p {'<' if u_p_value < alpha else '>='} {alpha})"
    )
    add_to_report("推断性统计检验 (过滤后数据)", "\n".join(inferential_results))

    # --- Effect Size Calculation ---
    effect_size_results = []
    n1, n2 = len(controller_latency), len(keyboard_latency)
    m1, m2_val = controller_latency.mean(), keyboard_latency.mean()
    s1, s2 = controller_latency.std(ddof=1), keyboard_latency.std(ddof=1) # ddof=1 for sample std dev

    if (n1 + n2 - 2) > 0:
         pooled_std = np.sqrt(((n1 - 1) * s1**2 + (n2 - 1) * s2**2) / (n1 + n2 - 2)) if (n1 + n2 - 2) > 0 else 0
         cohen_d = (m1 - m2_val) / pooled_std if pooled_std != 0 else 0
    else:
        cohen_d = 0
        pooled_std = 0
    effect_size_results.append(
        f"  Cohen's d (针对t检验的均值差异):\n"
        f"    d = {cohen_d:.3f} (池化标准差: {pooled_std:.2f} ms)\n"
        f"    解释指南: |d|≈0.2 '小效应', |d|≈0.5 '中效应', |d|≈0.8 '大效应'"
    )

    mean_U = n1 * n2 / 2.0
    std_U = np.sqrt(n1 * n2 * (n1 + n2 + 1) / 12.0) if (n1 + n2 + 1) > 0 else 0
    # Adjust U for Z calculation: U for Z should be min(U1, U2) or use direct Z from scipy if available.
    # Scipy's u_stat for two-sided is U1 = R1 - n1(n1+1)/2.
    # Z = (U1 - n1*n2/2) / std_U
    z_mw = (u_stat - mean_U) / std_U if std_U !=0 else 0
    r_biserial_abs = np.abs(z_mw) / np.sqrt(n1 + n2) if (n1 + n2) > 0 else 0

    effect_size_results.append(
        f"\n  Rank Biserial Correlation (r) (针对Mann-Whitney U的分布差异):\n"
        f"    (基于计算的Z值: {z_mw:.3f})\n"
        f"    |r| = {r_biserial_abs:.3f} (绝对值)\n"
        f"    解释指南: |r|≈0.1 '小效应', |r|≈0.3 '中效应', |r|≈0.5 '大效应'"
    )
    add_to_report("效应量计算 (过滤后数据)", "\n".join(effect_size_results))

    # --- Equivalence Testing (TOST) for means ---
    d_obs = m1 - m2_val
    tost_report_parts = [f"  等效边界 (Delta): +/- {equivalence_delta:.2f} ms"]
    tost_report_parts.append(f"  观察到的平均值差异 (手柄 - 键盘): {d_obs:.2f} ms")
    
    df_tost = n1+n2-2
    if df_tost > 0 :
        s_p_squared = ((n1 - 1) * s1**2 + (n2 - 1) * s2**2) / df_tost
        if (1/n1 + 1/n2) > 0 and s_p_squared >=0:
            se_diff = np.sqrt(s_p_squared * (1/n1 + 1/n2))
        else:
            se_diff = 0
    else:
        se_diff = 0

    if se_diff > 0:
        t_lower = (d_obs - (-equivalence_delta)) / se_diff
        p_lower = 1 - stats.t.cdf(t_lower, df=df_tost)

        t_upper = (d_obs - equivalence_delta) / se_diff
        p_upper = stats.t.cdf(t_upper, df=df_tost)

        tost_report_parts.append(f"  TOST p-value (下边界): {p_lower:.4e} (检验 手柄均值-键盘均值 > -{equivalence_delta:.2f} ms)")
        tost_report_parts.append(f"  TOST p-value (上边界): {p_upper:.4e} (检验 手柄均值-键盘均值 < +{equivalence_delta:.2f} ms)")

        equivalence_achieved = (p_lower < alpha) and (p_upper < alpha)
        tost_report_parts.append(f"  等效性结论 (基于alpha={alpha}): {'达到等效性' if equivalence_achieved else '未达到等效性'}")

        conf_level_tost = 1 - 2 * alpha
        t_crit_tost = stats.t.ppf(1 - alpha, df=df_tost)
        ci_lower = d_obs - t_crit_tost * se_diff
        ci_upper = d_obs + t_crit_tost * se_diff
        tost_report_parts.append(f"  均值差值的 {conf_level_tost*100:.0f}% 置信区间: [{ci_lower:.2f} ms, {ci_upper:.2f} ms]")
        ci_within_bounds = (ci_lower > -equivalence_delta) and (ci_upper < equivalence_delta)
        tost_report_parts.append(f"  该置信区间是否完全落在 [+/-{equivalence_delta:.2f} ms] 内: {ci_within_bounds}")
    else:
        tost_report_parts.append("  无法计算TOST (标准误差为0或自由度不足)。")
    add_to_report("等效性检验 (TOST) - 比较平均值 (过滤后数据)", "\n".join(tost_report_parts))

except ValueError as ve: # Catch the specific error for insufficient data
     add_to_report("分析中止", str(ve))
except Exception as e:
    add_to_report("脚本执行时发生主要意外错误", f"错误信息: {str(e)}\n请检查数据文件和脚本逻辑。")

# --- Generate Full Report ---
print("="*80)
print("数据分析报告")
print("="*80)
for section_content in report_sections:
    print(section_content)
    print("-"*80)

print("\n报告结束。")
    ```

  ]
]

    