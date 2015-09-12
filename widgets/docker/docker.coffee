class Dashing.Docker extends Dashing.Widget

  # This is fired when the widget is done being rendered
  ready: ->

  # Change widget color if something happens
  onData: (data) ->
    #console.log(data)

    if data.state == "green"
      $(@node).fadeOut().css('background-color', '#13c83f').fadeIn()

    else if data.state == "yellow"
      $(@node).fadeOut().css('background-color', '#ecbe3c').fadeIn()

    else if data.state == "red"
      $(@node).fadeOut().css('background-color', '#c83f13').fadeIn()

    else if data.state == "unknown"
      $(@node).fadeOut().css('background-color', '#343434').fadeIn()
