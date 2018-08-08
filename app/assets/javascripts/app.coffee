window.App =
  alert: (msg, to) ->
    $(to).before("<div class='alert alert-danger' id='alert-comp'><a class='close' href='#' data-dismiss='alert'>×</a>#{msg}</div>")
  
  notice: (msg, to) ->
    $(to).before("<div class='alert alert-success' id='notice-comp'><a class='close' href='#' data-dismiss='alert'>×</a>#{msg}</div>")
  
  selectMoney: (money) -> 
    $('#current-money').text(money)
  changeMoney: (el) -> 
    val = $(el).val()
    reg = /^[0-9]*[1-9][0-9]*$/
    if reg.test(val)
      $('#current-money').text(val)
  
  # 获取当前位置信息
  getLocation: (successCallback, errorCallback) ->
    geolocation = new qq.maps.Geolocation('EJZBZ-VCM34-QJ4UU-XUWNV-3G2HJ-DWBNJ', 'yujian')
    geolocation.getLocation(successCallback, errorCallback, {timeout: 8000})
  
  # 获取微信位置信息
  getWXLocation: (successCallback, errorCallback) ->
    wx.getLocation({ type: 'gcj02', success: successCallback, fail: errorCallback });
  
  # 配置微信
  wxConfig: (data, successCallback, errorCallback) -> 
    wx.config(data)
    wx.ready(successCallback)
    wx.error(errorCallback)
  
  getToken: () ->
    return window.localStorage.getItem('token')
    
  saveToken: (token) -> 
    if token
      window.localStorage.setItem('token', token)
  
  # 查看红包
  viewRedpack: () ->
    $el = $('.redpack-box')
    id = $el.data('id')
    token = $el.data('user')
    
    successCallback = (pos) ->
      App._viewRedpack(id, token, "#{pos.lng},#{pos.lat}");

    errorCallback   = (error) ->
      App._viewRedpack(id, token, null)

    App.getLocation(successCallback, errorCallback)
  
  _viewRedpack: (id, token, pos) ->
    i = Utils.getRandomString(18)
    ak = Utils.getAccessKey(i)
    
    $.ajax
      url: "/api/v1/redpack/view"
      type: "POST"
      data: { token: token, id: id, from_type: 1, loc: pos, i: i, ak: ak }
      success: (re) ->
        console.log(re)
      error: (er) ->
        console.log(er)
    
  # 拆红包
  takeRedpack: (el) -> 
    $el = $(el)
    id = $el.data('id')
    token = $el.data('user')
    sign = $el.data('sign')
    if sign == '1'
      $('#myModal').modal('show')
      return
    App.openRedpack($el, id, token, null)
    
  # 拆口令红包
  takeSignRedpack: (el) ->
    $el = $(el)
    id = $el.data('id')
    token = $el.data('user')
    sign = $('#sign-input-control').val()
    if !sign
      App.alert('口令不能为空', '#sign-input-control')
      return
    
    App.openRedpack($el, id, token, sign)
  
  openRedpack: (el, id, token, sign) ->
    successCallback = (pos) ->
      # console.log(pos)
      loc = "#{pos.lng},#{pos.lat}"
      App._openRedpack(el, id, token, sign, loc)
      
    errorCallback   = (error) ->
      # console.log(error)
      App._openRedpack(el, id, token, sign, null)
    
    App.getLocation(successCallback, errorCallback)
  
  _openRedpack: (el, id, token, sign, loc) ->
    i = Utils.getRandomString(18)
    ak = Utils.getAccessKey(i)
    
    loading = el.data('loading')
    if loading == '1'
      return
    
    el.data('loading', '1')
    
    $.ajax
      url: "/api/v1/redpack/take"
      type: "POST"
      data: { token: token, id: id, loc: loc, sign: sign, i: i, ak: ak }
      success: (re) ->
        # console.log(re)
        el.data('loading', '0')
        if re.code == 0
          $('#myModal').modal('hide')
          window.location.href = "/redpack/result?id=" + re.data.id
        else
          alert(re.message)
      error: (er) ->
        el.data('loading', '0')
        # console.log(er)
        alert(er)
          
  viewHB: (hbid, i, ak) ->
    successCallback = (pos) ->
      App._viewHB(hbid, "#{pos.lng},#{pos.lat}", i, ak);

    errorCallback   = (error) ->
      App._viewHB(hbid, null, i, ak)

    App.getLocation(successCallback, errorCallback)
  
  _viewHB: (hbid, loc, i, ak) ->
    token = App.getToken()
    
    $.ajax
      url: "/api/v1/hb/#{hbid}/view"
      type: "POST"
      data: { token: token, from_type: 1, loc: loc, i: i, ak: ak }
      success: (re) ->
        console.log(re)
      error: (er) ->
        console.log(er)
  
  commitHBData: (eventId, payload, i, ak, type) ->
    # console.log(eventId)
    # console.log(payload)
    token = App.getToken()
    url = ''
    if type == 'Question' || type == 'LocationCheckin'
      url = "/api/v1/hb/#{eventId}/commit"
    else if type == 'CheckinRule' || type == 'QuizRule'
      url = "/api/v1/events/#{eventId}/commit"
    
    if url == ''
      return
    
    $.ajax
      url:  url,
      type: "POST"
      data: { token: token, payload: payload, from_user: window.localStorage.getItem('from_user'), i: i, ak: ak }
      success: (re) ->
        $('#commitBtn').button('reset')
        # $('#hb-result-modal').modal({
        #   backdrop: 'static',
        # })
        if re.code == 0
          # $('#hb-result').text(re.data.money + ' 元')
          # $('#hb-result').addClass('hb-result-success')
          # $('#follow-tip').html('<p>零钱已入您的小优大惠钱包！</p><p>识别二维码，关注公众号领取！</p>')
          # $('#result-tip').text('恭喜发财，大吉大利！')
          window.location.href="/wx/share/result?id=#{eventId}&type=#{type}&money=#{re.data.money}"
        else
          window.location.href="/wx/share/result?id=#{eventId}&type=#{type}&code=1&message=#{re.message}"
          # $('#hb-result').text(re.message)
          # $('#hb-result').addClass('hb-result-fail')
          # $('#follow-tip').html('<p>识别二维码，关注公众号</p><p>领取更多红包！</p>')
          # $('#result-tip').text('温馨提示')
          # console.log(re.message)
      error: (error) ->
        $('#commitBtn').button('reset')
        window.location.href="/wx/share/result?code=500&id=#{eventId}&type=#{type}"
        # alert('服务器出错，请稍后再试！');
        # $('#hb-result-modal').modal({
        #   backdrop: 'static',
        # })
        # $('#hb-result').text('服务器出错，请稍后再试！')
        # $('#hb-result').addClass('hb-result-fail')
        # $('#follow-tip').html('<p>识别二维码，关注公众号</p><p>领取更多红包！</p>')
        # $('#result-tip').text('温馨提示')
        # console.log('提交失败: ' + error)
        
  commitQuziHB: (eventId, i, ak, type) ->
    answer = $("input[name='answerOption']:checked").val()
    if !answer
      $('#commitBtn').button('reset')
      alert('请先选择答案')
      return
    
    successCallback = (pos) ->
      # console.log(pos)
      payload = JSON.stringify({ answer: answer, location: "#{pos.lng},#{pos.lat}" })
      App.commitHBData(eventId, payload, i, ak, type)
      
    errorCallback   = (error) ->
      # console.log(error)
      payload = JSON.stringify({ answer: answer, location: null })
      App.commitHBData(eventId, payload, i, ak, type)
    
    App.getLocation(successCallback, errorCallback)
  commitCheckinHB: (eventId, i, ak, type) ->
    successCallback = (pos) ->
      # console.log(pos)
      payload = JSON.stringify({ location: "#{pos.lng},#{pos.lat}" })
      App.commitHBData(eventId, payload, i, ak, type)
      
    errorCallback   = (error) ->
      $('#commitBtn').button('reset')
      alert('获取位置失败')
    
    App.getLocation(successCallback, errorCallback)
    
    # App.getLocation((pos) -> {
    #     loc = "#{pos.lng},#{pos.lat}"
    #     payload = JSON.stringify({ location: loc })
    #     App.commitHBData(eventId, payload, i, ak)
    #   }, (error) -> {
    #     alert('获取位置失败，请重试')
    #     # payload = JSON.stringify({ answer: answer, location: null })
    #     # App.commitHBData(eventId, payload, i, ak)
    #   })
      
  # 提交红包
  commitHB: (eventId, eventType, i, ak) -> 
    if eventType == 'QuizRule' || eventType == 'Question'
      App.commitQuziHB(eventId, i, ak, eventType)
    else if eventType == 'CheckinRule' || eventType == 'LocationCheckin'
      App.commitCheckinHB(eventId, i, ak, eventType)
      # console.log('eee')
  
  # 抢红包
  grabHongbao: (el,i,ak) -> 
    token = window.localStorage.getItem('token')
    # alert(token)
    if !token
      wxAuthUrl = $(el).data('auth-url')
      # alert(wxAuthUrl)
      window.location.href = wxAuthUrl
      return
    
    $(el).button('loading');
           
    eventId = $(el).data('eid')
    eventType = $(el).data('type')
    # $('.grab-btn a').attr('disabled');
    App.commitHB(eventId, eventType, i, ak)
  
  # 发送分享统计
  sendShareStat: (token, eventId, i, ak) ->
    $.ajax
      url: "/api/v1/share/event",
      type: "POST"
      data: { token: token, event_id: eventId, i: i, ak: ak }
  # 发送分享统计
  sendShareStat2: (token, hbId, i, ak) ->
    $.ajax
      url: "/api/v1/share/redbag",
      type: "POST"
      data: { token: token, redbag_id: hbId, i: i, ak: ak }
      
  # 注册微信分享
  wxShare: (data, successCallback,cancelCallback,errorCallback) -> 
    # 分享到朋友圈
    wx.onMenuShareTimeline({
      title: data.title,
      link: data.link,
      imgUrl: data.img_url,
      success: successCallback,
      cancel: cancelCallback,
      fail: errorCallback
    })
    # 分享给微信好友
    wx.onMenuShareAppMessage({
      title: data.title,
      desc: data.desc,
      link: data.link,
      imgUrl: data.img_url,
      type: '', # 分享类型,music、video或link，不填默认为link
      dataUrl: '', # 如果type是music或video，则要提供数据链接，默认为空
      success: successCallback,
      cancel: cancelCallback,
      fail: errorCallback
    })
    
    # 分享给QQ好友
    wx.onMenuShareQQ({
      title: data.title,
      desc: data.desc,
      link: data.link,
      imgUrl: data.img_url,
      success: successCallback,
      cancel: cancelCallback,
      fail: errorCallback
    })
    
    # 分享到QQ空间
    wx.onMenuShareQZone({
      title: data.title,
      desc: data.desc,
      link: data.link,
      imgUrl: data.img_url,
      success: successCallback,
      cancel: cancelCallback,
      fail: errorCallback
    })
    
  getCode: (auth_code_api, el, i, ak) ->
    $('#alert-comp').remove()
    $('#notice-comp').remove()
    if $(el).data("loading") == '1'
      return false
      
    mobile = $("#user_mobile").val()
    blank_mobile = mobile.replace(/\s+/, "")
    if blank_mobile.length == 0
      App.alert("手机号不能为空", $('#signup_form'))
      return false
    
    # captcha = $("#user_captcha").val()
    # if captcha.length == 0
    #   App.alert("图片验证码不能为空", $('#new_user'))
    #   return false
      
    reg = /^1[3|4|5|8|7][0-9]\d{8}$/
    if not reg.test(mobile)
      App.alert("不正确的手机号", $('#signup_form'))
      return false
    
    # 防止重复点击
    if $(el).data("loading") == '1'
      return
    $(el).data("loading", '1')
    
    $.ajax
      url:  auth_code_api,
      type: "POST"
      data: { mobile: mobile, i: i, ak: ak }
      success: (re) -> 
        if re.code == 0
          App.notice("获取验证码成功", $('#signup_form'))
          
          # 计时器开始倒计时
          $(el).attr("disabled", true)
          
          $(el).text('59秒后重新获取')
          total = 58
          timer = setInterval (->
            if total == 0
              clearInterval(timer)
              $(el).removeAttr("disabled")
              $(el).text("获取验证码")
              $(el).data("loading", '0')
              return
      
            $(el).text((total--) + '秒后重新获取')
          ), 1000
          
        else
          # clearInterval(timer)
          $(el).data("loading", '0')
          $(el).removeAttr("disabled")
          $(el).text("获取验证码")
          App.alert(re.message, $('#signup_form'))
      error: (re) ->
        $(el).data("loading", '0')
        $(el).removeAttr("disabled")
        $(el).text("获取验证码")
        App.alert(re.message, $('#signup_form'))
  
  deleteItem: (el) ->
    # result = confirm("您确定吗？")
    # if !result
    #   return false
    
    loading = $(el).data("loading")
    if loading == '1'
      return false
    
    $(el).data("loading", '1')
    
    id = $(el).data("id")
    type = $(el).data("type")
    $.ajax
      url: "/line_items/#{id}"
      type: "DELETE"
      data: { type: type }
  
  # 开始抽奖
  startCJ: (el) ->
    # alert($(el));
    has_prized = $(el).data("has-prized")
    if has_prized.toString() == 'true'
      alert('您已经参与过抽奖了，不能重复参与。')
      return false
    
    loading = $(el).data("loading")
    if loading == '1'
      return false
    $(el).data("loading", '1')
    
    $('#cj-result').html('正在抽奖，请稍后...');
    
    id = $(el).data("id");
    
    $.ajax
      url: "/wx/cj/#{id}/begin"
      type: "POST"
      data: { loc: $(el).data('loc') }
      # success: (re) -> 
      #   if re == "1"
      #     
      #   else
      #     alert(re)
      # error: (re) ->
      #   alert("服务器出错了")
  showCJDesc: () ->
    $('#cl-desc').modal({
      backdrop: 'static',
    });
      
  showCJResult: (el) ->
    id = $(el).data('id')
    
    $('#cl-result').modal({
      backdrop: 'static',
    });
    
    $('#cl-result .modal-body').html('数据加载中...');
    $.ajax
      url: "/wx/cj/#{id}/results",
      type: "GET",
      # data: { i: $(el).data('code').toString(), ak: $(el).data('key').toString() },
      # success: (re) -> 
      #   console.log(re)
      #   
      #   data = re.data
      #   
      #   if data.length == 0
      #     $('#cl-result .modal-body').html('暂无数据');
      #   else
      #     html = '<table class="table">'        
      #     for item in data
      #       html += "<tr><td width=\"18%\"><img src=\"#{item.user.avatar}\" class=\"img-circle\" style=\"width:32px;height:32px;\"></td><td><span style=\"color: red;\">#{item.user.nickname}</span>抽中<span style=\"color: red;\">#{item.prize.name}</span></td><td width=\"30%\">#{moment(item.time, "YYYY-MM-DD hh:mm:ss").fromNow()}</td></tr>"
      #     html += '</table>'
      #     $('#cl-result .modal-body').html(html);
      # error: (re) ->
      #   $('#cl-result .modal-body').html('数据加载失败~');
      
  # 完成订单
  completeOrder: (el) ->
    loading = $(el).data("loading")
    if loading == '1'
      return false
    
    $(el).data("loading", '1')
    
    id = $(el).data("id")
    current = $(el).data("current")
    
    $.ajax
      url: "/orders/#{id}/complete"
      type: "PATCH"
      data: { 'current': current }
    
    
  # 取消订单
  cancelOrder: (el) ->
    result = confirm("您确定吗？")
    if !result
      return false
      
    loading = $(el).data("loading")
    if loading == '1'
      return false
    
    $(el).data("loading", '1')
    
    id = $(el).data("id")
    current = $(el).data("current")
    
    $.ajax
      url: "/orders/#{id}/cancel"
      type: "PATCH"
      data: { 'current': current }
    
  # 更新状态
  updateState: (el) ->
    result = confirm("你确定吗?")
    if !result
      return false
    
    state = $(el).data("state")
    
    if state == true
      url = $(el).data("yes-uri")
    else
      url = $(el).data("no-uri")
      
    $.ajax
      url: url
      type: "PATCH"
      success: (re) ->
        if re == "1"
          if state == true
            $(el).text($(el).data("no-text"))
            $(el).data("state", false)
          else 
            $(el).text($(el).data("yes-text"))
            $(el).data("state", true)
        else
          App.alert("抱歉，系统异常", $(el))