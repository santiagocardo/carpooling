defmodule CarpoolingWeb.PositionComponent do
  use CarpoolingWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <input
      id="current-position"
      name="position"
      type="hidden"
      phx-update="ignore"
      phx-hook="SetCurrentPosition"
    >
    """
  end
end
