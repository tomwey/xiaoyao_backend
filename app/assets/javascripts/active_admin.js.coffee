#= require arctic_admin/base
#= require jquery.chosen
#= require lucky_draw.mRotate
#= require lucky_draw.utils
#= require redactor-rails/redactor
#= require redactor-rails/config
#= require redactor-rails/langs/zh_cn
#= require redactor-rails/plugins
#= require fusioncharts/fusioncharts
#= require fusioncharts/fusioncharts.charts
#= require fusioncharts/themes/fusioncharts.theme.fint

window.Media =
  
  # 作品类型切换
  toggleMediaType: (type) ->
    if type == '1' # 电台
      $('#radio-content').show()
    else if type == '2' # MV
      $('#radio-content').hide()
  
  showRadioInputs: (flag) ->
    if flag
      $('#radio-content').show()
    else
      $('#radio-content').hide()

$(document).ready ->
  
  $("select").chosen({"search_contains": true, "no_results_text":"没有找到", "placeholder_text_single":"--请选择--"});

  Media.showRadioInputs($('#radio-content').data('need-show') == 1)
  
  $('#media__type').change -> 
    type = $(this).val()
    Media.toggleMediaType(type)