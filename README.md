# Typst 西安电子科技大学本科毕业设计论文模板

📖 基于Typst的XIDIAN本科毕设论文模板 | 简洁高效·符合学校规范

本模板基于typst0.13,遵循《西安电子科技大学本科毕业设计撰写规范》要求，设计了一个轻量化的模板。包括论文封面和摘要后的所有内容。 封面部分不同学院可能略有不同，建议在学校给的word基础上填写后合并pdf。

## 使用方法：

### 安装Typst

1. 在vscode插件市场中安装tinymist插件
2. 克隆本项目

```bash
git clone git@github.com:juruoHBr/typst_xdutemplate.git
```

### 在config.typ中配置和填写信息

```typ
#let config-dict = (
  title: ("基于SIP多媒体系统的数据会议","研究与实现"),
  class-number: [2101011],
  student-number:[2101010025],
  student-name: [张~~三],
  school-name: [通信工程学院],
  major-name: [通信工程],
  teacher-name: [李~~四],
  "teacherInXDU-name":[（如无院内导师，则无需写此条）],

	ch-heading-font: ("SimHei","SimSun","SimSun"),
	en-heading-font: ("Times New Roman","Times New Roman","Times New Roman"),
  heading-fontsize: (16pt,14pt,12pt),
	ch-main-font: "SimSun",
	en-main-font: "Times New Roman",
  main-fontsize: 12pt,
  caption-fontsize: 10.5pt,
  header-fontsize: 10.5pt,
  pagenum-fontsize: 9pt
)
```

### 在main.typ中填写内容

```typ
#import "template/template.typ": *

#show: xdudoc.with()


// 这里包括摘要和目录
#front-matter[
  #abstract(
    ch-keywords: [*Typst* ~~~ *xdutemplate* ~~~~ 西电本科论文模板],
    en-keywords: [Typst ~~~ xdutemplate ],
  )[
    这里是中文摘要。
  ][
    This is English abstract.

    This is English abstract.
  ]
  #thesis-contents()
]

// 这里是正文
#mainbody[
  = 这里是第一章 <CH1>

  这里是第一章。

  == 这是第一小节 <CHH1>
  === 这是第一小小节
  这里有一个公式：
  $
    f=1
  $<cc>

  @cc 是一个公式。

  这里还有一个公式，并且该公式后一段不缩进。
  $
    g=2
  $
  #h(-2em)段后内容。

  这里有个图和一个表，并且放置在原处

  #figure(
    rect(width: 5cm, height: 5cm),
    caption: [ddd],
    placement: none
  )

  #figure(
    table([1], [2]),
    caption: [dd],
    placement: none
  )<dd>

  @dd 是一个很好的表
  #figure(
    rect(width: 5cm, height: 5cm),
    caption: [ddd],
  )<abc>
  
  @abc 是一个浮动的图

  ==== 这是四级标题

  - 列表第一点
  - 列表第二点

  + 有序列表1
  + 有序列表2

  这里有两个引用文献：

  文献1 @李斌2012极化码原理及应用

  文献2 @2001The

]

// 这里是参考文献，致谢和附录
#after-matter[
  #bibliography("ref.bib",style: "gb-7714-2015-numeric")

  = 致谢
  谢谢大家
  #appendix[
    = 这是附录A
    #figure(
      rect(width: 5cm, height: 5cm),
      caption: [测试],
    )
    $
      f + g
    $<eqq>
    可以看到，附录的表和@eqq 的编号都没有问题。

  ]
]

```

## Changelog

2025.3.18：更新封面参数

2025.3.17: 将四级标题从目录里移除，将图片设置为默认浮动（可在config.typ 里更改）

2025.3.13: 添加了四级标题，修改了列表的缩进和有序列表默认格式，增加了引用样式. 将template.typ移动到template文件夹中，修改模板时仅需要替换template文件夹

2025.3.9： 添加了封面，整理了项目的结构

2025.3.7： 为typst0.13 进行了模板修改

## 如何更新模板

仅需将仓库中template最新文件夹替换本地的template文件夹即可

## 常见问题

[常见问题 | Typst 中文社区导航](https://typst-doc-cn.github.io/guide/FAQ.html)
