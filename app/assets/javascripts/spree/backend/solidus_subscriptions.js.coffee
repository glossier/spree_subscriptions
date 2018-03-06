$(document).ready ->
  #handle edit click
  $('a.edit-subscription-item').click toggleSubscriptionItemEdit

  #handle cancel click
  $('a.cancel-subscription-item').click toggleSubscriptionItemEdit

  #handle save click
  $('a.save-subscription-item').click ->
    save = $ this
    subscription_item_id = save.data('subscription-item-id')
    quantity = parseInt(save.parents('tr').find('input.subscription_item_quantity').val())

    adjustSubscriptionItem(subscription_item_id, quantity)
    false

  # handle delete
  $('a.delete-subscription-item').click ->
    if confirm(Spree.translations.are_you_sure_delete)
      del = $(this);
      subscription_item_id = del.data('subscription-item-id');

      deleteSubscriptionItem(subscription_item_id)

  # handle adding
  $('#add_subscription_item_variant_id').change ->
    variant_id = parseInt($(this).val())
    variant = _.find(window.variants, (variant) ->
      variant.id == variant_id
    )
    variantLineItemTemplate = HandlebarsTemplates["variants/line_items_autocomplete_stock"];
    $('#stock_details').html variantLineItemTemplate(variant: variant)
    $('#stock_details').show()
    $('button.add_variant').click addSubscriptionVariant

  # handle the tabs
  $('.subscription.tabs li > a').click ->
    targetTab = $(this).data('target')
    $('.subscription.tab-container > div').hide()
    $('div#' + targetTab).show()


toggleSubscriptionItemEdit = ->
  link = $(this);
  link.parent().find('a.edit-subscription-item').toggle();
  link.parent().find('a.cancel-subscription-item').toggle();
  link.parent().find('a.save-subscription-item').toggle();
  link.parent().find('a.delete-subscription-item').toggle();
  link.parents('tr').find('td.subscription-item-qty-show').toggle();
  link.parents('tr').find('td.subscription-item-qty-edit').toggle();

  false

subscriptionItemURL = (subscription_id, subscription_item_id) ->
  url = Spree.pathFor('api/subscriptions/' + subscription_id + '/subscription_items/' + subscription_item_id)

adjustSubscriptionItem = (subscription_item_id, quantity) ->
  url = subscriptionItemURL(subscription_id, subscription_item_id)
  $.ajax(
    type: "PUT",
    url: Spree.url(url),
    data:
      subscription_item:
        quantity: quantity
      token: Spree.api_key
  ).done (msg) ->
    show_flash 'success', 'Successfully updated the item quantity.'
    findSubscriptionItemRow(subscription_item_id)
      .find('.subscription-item-qty-show').text(quantity)
    findSubscriptionItemRow(subscription_item_id)
      .find('a.edit-subscription-item').trigger 'click'

deleteSubscriptionItem = (subscription_item_id) ->
  url = Spree.pathFor('api/subscriptions/' + subscription_id + '/subscription_items/' + subscription_item_id)
  $.ajax(
    type: "DELETE"
    url: Spree.url(url)
    data:
      token: Spree.api_key
  ).done (msg) ->
    $('#subscription-item-' + subscription_item_id).remove()
    if $('.subscription-items tr.subscription-item').length == 0
      $('.subscription-items').remove()


addSubscriptionVariant = ->
  $('#stock_details').hide()
  variant_id = $('input.variant_autocomplete').val()
  inputs = $('input.quantity[data-variant-id=\'' + variant_id + '\']')
  sorted = inputs.sort (a, b) ->
    return $(a).val() < $(b).val()
  quantity = sorted[0].value
  adjustSubscriptionItems subscription_id, variant_id, quantity

adjustSubscriptionItems = (subscription_id, variant_id, quantity) ->
  url = Spree.pathFor('api/subscriptions/' + subscription_id + '/subscription_items')
  $.ajax(
    type: 'POST'
    url: Spree.url(url)
    data:
      subscription_item:
        variant_id: variant_id
        quantity: quantity
      token: Spree.api_key).done (msg) ->

findSubscriptionItemRow = (subscription_item_id) ->
  $('tr#subscription-item-' + subscription_item_id)
