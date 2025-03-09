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
