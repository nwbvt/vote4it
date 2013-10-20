Template.polls.events(
  'submit #newPollForm' : (event, template) ->
    input = event.target.elements[0]
    name = input.value
    console.log "New Poll with name: #{name}"
    Polls.insert({name: name, create_date: new Date(), create_user: Meteor.userId(), votes: []})
    input.value=""
    return false
)

Template.onepoll.hasVoted = () ->
  poll = Polls.findOne(Session.get("poll_id"))
  revote = Session.get("revote")
  return true if hasVoted(poll) and not revote

hasVoted = (poll) ->
   _.contains(_.pluck(poll.votes, "user_id"), Meteor.userId())

Template.vote.getOrderedItems = () ->
  result = []
  votes = _.find(this.votes, (vote) ->
    return vote.user_id is Meteor.userId()
  )
  if votes
    for vote in votes.votes
      result.push _.find(this.items, (item) ->
        return Number item.id == Number vote
      )
    result_ids = _.pluck(result, "id")
    for item in this.items
      if !_.contains(result_ids, item.id)
        result.push item
  else
    result = this.items
  result

Template.vote.events(
  'submit #newItemForm' : (event, template) ->
    pollId = $("#poll-id").val()
    name =  $("#item-name").val()
    result = Meteor.call "addItem", pollId, name
    $("#item-name").val("")
    return false
  'click #submit-vote' : (event, template) ->
    sortedIDs = $(".sortable").sortable( "toArray" )
    pollId = $(event.target).data("poll-id")
    poll = Polls.findOne(pollId)
    if hasVoted(poll)
      Polls.update( pollId, { $pull: { "votes" : { user_id: Meteor.userId() } } } )
    
    data =
      user_id: Meteor.userId()
      votes: sortedIDs
      date: new Date()
    Polls.update(pollId, $addToSet: votes: data)
    Session.set("revote", null)
)
        
Template.vote.rendered = () ->
  $( ".sortable" ).sortable()
  $( ".sortable" ).disableSelection()

Template.results.events(
  'click #revote' : (event, template) ->
    pollId = Session.get("poll_id")
    Session.set("revote", true)
)

Template.results.sortedResults = () ->
  poll = Polls.findOne(Session.get("poll_id"))
  _.sortBy(poll.items, (item) ->
    item.points = pointsFor poll, item.id
    return item.points * -1
  )


pointsFor = (poll, item_id) ->
  points = 0
  total = poll.items.length
  for vote in poll.votes
    location = _.indexOf(vote.votes, item_id+"")
    if location>=0
      points = points + (total - location)
    else
      points = 0
  points
