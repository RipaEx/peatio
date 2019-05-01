//= require jquery3
//= require popper

window.onload = function () {

  $('#send-code-btn').on('click', function () {
    $('.loader').css("display", "block");
    $('#send-code-btn').hide();
    number = $("#country_code").val() + $("#number").val();
    $.ajax({
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      method:  'POST',
      data:    { number: number },
      url:     '/settings/edit_profile/phones_verification',
      success: function(result){
         if (result.success){
           $('.loader').css("display", "none");
           $('#send-code-btn').show();
           $("#create-phone").prop('disabled', false);
           $("#send-code-btn").text('Resend');
           if (result.message) {
            $("#error").text(result.message);
           } else {
            $("#error").text('');
           }
         } else {
           $('.loader').css("display", "none");
           $('#send-code-btn').show();
           $("#error").text(result.error);
         }
      }
    });
  });
};
