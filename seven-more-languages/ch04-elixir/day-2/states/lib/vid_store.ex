defmodule VidStore do
  use StateMachine

  state :available,
    [ rent: 
      [ to: :rented,
        calls:
        [ &VidStore.renting/1 ]] ]

  state :rented,
    [ return: 
      [ to: :available,
        calls:
        [ &VidStore.returning/1 ]],
      lose:
      [ to: :lost,
        calls:
        [ &VidStore.losing/1 ]] ]

  # modified when doing exercise
  state :lost, 
    [ found:
      [ to: :available,
        calls:
        [ &VidStore.found_action/1 ]] ]
  
  def renting(video) do
    vid = log(video, "Renting #{video.title}")
    %{vid | times_rented: (video.times_rented + 1)}
  end
  
  def returning(video), do: log(video, "Returning #{video.title}")

  def losing(video), do: log(video, "Losing #{video.title}")

  # I admit this function name is somehow odd than other ones,
  # because "found" is both an event and an action,
  # and we will be generating a function called "found",
  # so here we'd better give it another name
  def found_action(video), do: log(video, "Found #{video.title}")

  def log(video, message) do
    %{video | log: [message | video.log]}
  end
end
