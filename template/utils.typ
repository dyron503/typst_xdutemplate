#import "../config.typ": *


#let hei(body)  = text(font: "SimHei", body)
#let kai(body)  = text(font: "KaiTi", body)

#let headings = state("headings",())


// 获取header的文本 type:string
#let getheadertext(loc,title, thiscontent:none) = {
	if( calc.even(loc.page()) ){
		if( thiscontent != none ){
			return thiscontent
		}
		return title
	}

	let headings_array = headings.final()
	let headerinfo =none
	for page_heading in headings_array{
		if int(loc.page()) < page_heading.pagenum{
			break
		}
		headerinfo =  page_heading
	}
	let header-format = headerinfo.heading.numbering
	if header-format != none{
		numbering(header-format,..headerinfo.heading-counter) + " "
	}
	headerinfo.heading.body
	
}


// 排版header
#let header-fun(numberformat: "1",cnt: counter(page),config: config-dict, thiscontent: none) = {
	let headercontext = {
		context {
			h(1fr)
			getheadertext(here(),config-dict.title.at(0)+config.title.at(1),thiscontent: thiscontent)
			h(1fr)
		}
	}  
	block(width: 100%, height: 100%, stroke: (bottom:0.75pt), inset: 0.5em,{
		text(size: config.header-fontsize)[#headercontext]
		context{
			set text(size: config.pagenum-fontsize)
			if(calc.odd( here().page() )){
				place(right+bottom)[#cnt.display(numberformat)]
			}
			else {
				place(left + bottom)[#cnt.display(numberformat)]
			}
		}
	})
}
