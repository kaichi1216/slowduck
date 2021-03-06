class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_new_conversation, only: [:show]
  before_action :find_message, only: [:show, :update]

  def index
  end

  def update
    @message.update(message_params)
    MessageRelayJob.perform_later(@message)
  end

  def show
    @message.notifications.where(recipient_id: current_user.id).update(read_at: Time.zone.now)
    @messages = @message.initialize_messages
  end

  def create
    message = Message.new(message_params)
    respond_to do |format|
      if message.save
        message.chatroom.chatroom_users.update(display: true)
        MessageRelayJob.perform_later(message)
        format.js
      end
    end
  end

  def destroy
  end

  private

  def message_params
    params.require(:message).permit(:body, :parent_id, :user_id, :chatroom_id, :image)
  end

  def find_message
    @message = Message.find(params[:id])
  end

  def set_new_conversation
    @conversation = Chatroom.new
    @conversation.chatroom_users.build
  end
end
