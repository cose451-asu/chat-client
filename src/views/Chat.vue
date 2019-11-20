<template>
  <div class="booker">
    <nav-bar :name="this.username"/>
    <div class="chat">
        <div class="container">
          <div class="msg-header">
              <div class="active">
                  <h5>#General</h5>
              </div>
          </div>

          <div class="chat-page">
              <div class="msg-inbox">
                  <div class="chats" id="chats">
                      <div class="msg-page" id="msg-page">

                        <div
                          v-if="loadingMessages"
                          class="loading-messages-container"
                        >
                          <spinner :size="100"/>
                          <span class="loading-text">
                            Loading Messages
                          </span>
                        </div>
                        <div class="text-center img-fluserId empty-chat" v-else-if="!groupMessages.length" >
                          <div class="empty-chat-holder">
                            <img src="../assets/empty-state.svg" class="img-res" alt="empty chat image">
                          </div>

                          <div>
                            <h2> No new message? </h2>
                            <h6 class="empty-chat-sub-title">
                              Send your first message below.
                            </h6>
                          </div>
                        </div>

                        <div v-else>
                          <div v-for="message in groupMessages" v-bind:key="message.id">
                            <div class="received-chats" v-if="message.sender.userId != userId">
                                <div class="received-msg">
                                    <div class="received-msg-inbox">
                                        <p><span>{{ message.sender.userId }}</span><br>{{ message.data.text }}</p>
                                    </div>
                                </div>
                              </div>


                            <div class="outgoing-chats" v-else>
                                  <div class="outgoing-chats-msg">
                                      <p>{{ message.data.text }}</p>
                                  </div>
                              </div>
                          </div>
                        </div>
                      </div>
                  </div>
              </div>

              <div class="msg-bottom">
                <form class="message-form" v-on:submit.prevent="sendGroupMessage">
                  <div class="input-group">
                    <input type="text" class="form-control message-input" placeholder="Type something" v-model="chatMessage" required>
                    <spinner
                      v-if="sendingMessage"
                      class="sending-message-spinner"
                      :size="30"
                    />
                  </div>
                </form>
              </div>
          </div>
      </div>
    </div>
  </div>
</template>

<script>
import NavBar from "../components/NavBar.vue";
import Spinner from "../components/Spinner.vue";

import { 
  ListChatRoomsRequest, 
  ListMyChatRoomsRequest,
  OpenChatRoomRequest,
  JoinChatRoomRequest,
  SayRequest,
  LeaveRequest
  } from '../../chat-service/chatroom_pb';
import { ChatRoomServiceClient } from '../../chat-service/chatroom_grpc_web_pb';

import {
  GetUsersRequest,
  GetMeRequest
  } from '../../chat-service/user_pb';
import { UserServiceClient } from '../../chat-service/user_grpc_web_pb';

import { RefreshTokenRequest } from '../../chat-service/auth_pb';
import { AuthServiceClient } from '../../chat-service/auth_grpc_web_pb';

const dest = process.env.VUE_APP_URL;

const chatroomClient = new ChatRoomServiceClient(dest);
const userServiceClient = new UserServiceClient(dest);
const authClient = new AuthServiceClient(dest);

export default {
  name: "home",
  components: {
    NavBar,
    Spinner
  },
  data() {
    return {
      username: "",
      userId: "",
      chatroomId: "",
      sendingMessage: false,
      chatMessage: "",
      loggingOut: false,
      groupMessages: [],
      usersList: [],
      lastSeq: 0,
      loadingMessages: false
    };
  },
  mounted() {
    this.loadingMessages = true

    var req = new ListChatRoomsRequest();

    var self = this;

    ChatRoomServiceClient.listChatRooms(req, {}, (err, res) => {
      if (err) {
        self.loadingMessages = false;
        console.log("Message fetching failed with error:", err);
      } else {
        console.log("this.groupMessages", this.groupMessages)
        self.groupMessages = [
          ...self.groupMessages
        ];
        self.loadingMessages = false
        self.$nextTick(() => {
          self.scrollToBottom();
        })
      }
    });
  },

  created() {
    this.getMyInfo();
  },
  methods: {
    fetch() {
      var req = new JoinChatRoomRequest();
      var chatroomId = this.chatroomId;
      req.setChatroomId(chatroomId);

      var lastSeq = this.lastSeq;
      req.setLastSequenceNr(lastSeq);

      var self = this;

      ChatRoomServiceClient.joinChatRoomRequest(req, {}, (err, res) => {
        self.lastSeq = res.sequence_nr;

        switch (res.event) {
          case 2:
            self.usersList = res.participated_user_ids;
            break;
          
          case 3:
            console.log("User joined", res.user_id);
            console.log("At", res.at);
            var joined_msg = res.user_id + " joined at " + res.at;
            self.groupMessages = [
              ...self.groupMessages,
              joined_msg
            ];
            self.$nextTick(() => {
              self.scrollToBottom();
            })
            break;
          
          case 4:
            console.log("User left", res.user_id);
            console.log("At", res.at);
            var exit_msg = res.user_id + " exit at " + res.at;
            self.groupMessages = [
              ...self.groupMessages,
              exit_msg
            ];
            self.$nextTick(() => {
              self.scrollToBottom();
            })
            break;

          case 5:
            console.log("Text message received successfully", res.message);
            self.groupMessages = [
              ...self.groupMessages,
              res.message
            ];
            self.loadingMessages = false
            self.$nextTick(() => {
              self.scrollToBottom();
            })
            break;

          default:
            console.log("Unknown state");
        }
      });
    },

    getMyInfo() {
      var req = new GetMeRequest();

      var self = this;

      userServiceClient.getMe(req, {}, (err, res) => {
        if (err) {
          self.$router.push({
            name: "homepage"
          });
          console.log(err);
        } else {
          self.userId = res.user.id;
          self.username = res.user.name;
        }
      });
    },

    getUsers() {
      var req = new GetUsersRequest();
      var users = this.users;
      req.setUserIdsList(users);

      var self = this;

      userServiceClient.getUsers(req, {}, (err, res) => {
        if (err) {
          self.$router.push({
            name: "homepage"
          });
          console.log(err);
        } else {
          self.usersList = res.users;
        }
      });
    },

    scrollToBottom() {
      const chat = document.getElementById("msg-page");
      chat.scrollTo(0, chat.scrollHeight + 30);
    },

    sendGroupMessage() {
      this.sendingMessage = true;
      var chatroomId = this.chatroomId;
      var messageText = this.chatMessage;
      let globalContext = this;

      var textMessage = new SayRequest();
      textMessage.setChatroomId(this.chatroomId);
      textMessage.setMessage(messageText);

      var self = this;

      ChatRoomServiceClient.sayRequest(textMessage, {}, (err, res) => {
        if (err) {
          console.log("Message sending failed with error:", err);
        } else {
          console.log("Message sent successfully:");
          self.chatMessage = "";
          self.sendingMessage = false;
          self.groupMessages = [...globalContext.groupMessages, textMessage];
          self.$nextTick(() => {
            self.scrollToBottom()
          })
        }
      });
    }
  }
};
</script>
