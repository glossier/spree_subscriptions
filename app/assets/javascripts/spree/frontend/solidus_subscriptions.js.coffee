$(document).ready ->
  $('.change-resume-subscription-on').click toggleResumeSubscriptionOn

toggleResumeSubscriptionOn = ->
  subscription = $(this).parents('tr');
  subscription.find('div.resume-subscription-on').toggle();
  subscription.find('div.subscription-will-resume-on').toggle();
