# Typst 西安电子科技大学本科毕业设计论文模板

📖 基于Typst的XIDIAN本科毕设论文模板 | 简洁高效·符合学校规范

本模板基于typst0.13,遵循《西安电子科技大学本科毕业设计撰写规范》要求，设计了一个轻量化的模板，由于论文封面不经常变动，且生成效果难以完全符合要求，因此本项目提供了封面和摘要之后部分的内容模板。

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
#import "template.typ": *

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

  这里有个图和一个表

  #figure(
    rect(width: 5cm, height: 5cm),
    caption: [ddd],
  )

  #figure(
    table([1], [2]),
    caption: [dd],
  )<dd>

  @dd 是一个很好的表


  这里有两个引用文献：

  文献1 @李斌2012极化码原理及应用

  文献2 @2001The

]

// 这里是参考文献，致谢和附录
#after-matter[
  #bibliography("ref.bib")

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

2025.3.13: 添加了四级标题，修改了列表的缩进和有序列表默认格式，增加了引用样式

2025.3.9： 添加了封面，整理了项目的结构

2025.3.7： 为typst0.13 进行了模板修改
