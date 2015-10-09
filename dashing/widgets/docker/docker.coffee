class Dashing.Docker extends Dashing.Widget

  constructor: ->
    super
    @none = '#343434'
    @green = '#13c83f'
    @yellow = '#ecbe3c'
    @red = '#c83f13'

  # This is fired when the widget is done being rendered
  ready: ->

  # Change widget color if something happens
  onData: (data) ->
    #console.log(data)

    if data.state == "ok"
      $(@node).fadeOut().css('background-color', @green).fadeIn()

    else if data.state == "warn"
      $(@node).fadeOut().css('background-color', @yellow).fadeIn()

    else if data.state == "error"
      $(@node).fadeOut().css('background-color', @red).fadeIn()

    else if data.state == "unknown"
      $(@node).fadeOut().css('background-color', @none).fadeIn()
