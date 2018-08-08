// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap
//= require app
//= require md5

$(document).ready(function() {
  $("#fixed-hb").hide();
  $("#random-hb").show();
  $("#hb-type").change(function() {
    // console.log($(this).val());
    var val = $(this).val();
    if (val === '0') {
      $("#fixed-hb").hide();
      $("#random-hb").show();
    } else {
      $("#random-hb").hide();
      $("#fixed-hb").show();
    }
  })
});

window.Utils = {
  getRandomString: function(len) {
    len = len || 32;
  　　var $chars = 'ABCDEFGHJKMNPQRSTWXYZabcdefhijkmnprstwxyz2345678';    /****默认去掉了容易混淆的字符oOLl,9gq,Vv,Uu,I1****/
  　　var maxPos = $chars.length;
  　　var pwd = '';
  　　for (i = 0; i < len; i++) {
  　　　　pwd += $chars.charAt(Math.floor(Math.random() * maxPos));
  　　}
  　　return pwd;
  },
  getAccessKey: function(str) {
    return hex_md5('c896833925be9f17633ffc386c97b1bb' + str)
  }
}
