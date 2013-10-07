jQuery(document).ready(function($) {
  $(".math").each(function(){
    var mathBlock = $(this);
    var formula = _.unescape(mathBlock.html());
    if (formula.substr(0,2)=="\\(") {
      var mathClass = "inline-math";
      formula = "$"+formula.slice(2,-2)+"$";
    } else {
      var mathClass = "display-math";
    }
    var preamble  = "\\usepackage{amsmath}\\usepackage{amsfonts}\\usepackage{amssymb}\\usepackage{xypic}\\usepackage{xifthen}\\usepackage{tikz}\\usepackage{fourier}";
    if(formula!="") {
      var qlQuery = 'formula=' + encodeURIComponent(formula)
                  + '&fsize='  + $(this).css("font-size")
                  + '&fcolor=' + '657b83' //default body color
//                  + '&mode=0' // auto, as by default
                  + '&out=2'; // svg
//                  + '&remhost=n-espresso.github.io';
      if (preamble!='')
        qlQuery = qlQuery + '&preamble=' + encodeURIComponent(preamble);
      var yqlQuery = "q=" +encodeURIComponent("select * from htmlpost where url='http://www.quicklatex.com/latex3.f/' and postdata=\""+qlQuery+"\" and xpath=\"//p\"")
                   + "&format=json"
                   + "&env=" +encodeURIComponent("store://datatables.org/alltableswithkeys");
      //console.log(qlQuery);
      //console.log(yqlQuery);
      $.ajax({
        url: 'http://query.yahooapis.com/v1/public/yql',
        dataType: 'json',
        data: yqlQuery,
        processData: false,
        timeout: 100000,
        //traditional: false,
        //global: false,
        success: function (response) {
          output = response.query.results.postresult.p;
          //console.log(output);
          if (output.length) {
            // Parse server response
            var pattern = /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s?([\S\s]*)/;
            var regs   = output.match(pattern);   
            var status = regs[1];
            var imgurl = regs[2];
            var valign = regs[3];
            var imgw   = regs[4];
            var imgh   = regs[5];
            var errmsg = regs[6];                               
            if(status=='0') {
              mathBlock.replaceWith("<img class=\""+mathClass+"\" style=\"vertical-align:-"+valign+"px;\" src=\""+imgurl.replace(".png",".svg")+"\" width=\""+imgw+"\" heigth=\""+imgh+"\" alt=\""+formula+"\"/>");
            } else {
              console.log("QuickLaTeX server returns error message: "+errmsg);
            }
          }
        },
        error: function (xhr,textStatus,errorThrown) {
          console.log("YQL server returns error message: "+xhr+responseText+textStatus+errorThrown);
        }
      });
    }
  });
});
