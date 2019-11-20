<template>
  <div class="login-page">
        <div class="login">
            <div class="login-container">
                  <div class="login-form-column">
                      <form v-on:submit.prevent="authLoginUser">
                          <h3>Hello!</h3>
                          <p>We are ASU with cose451 course</p>
                          <p><a href="https://github.com/cose451-asu">Link to Github repository</a></p>
                          <div class="form-wrapper">
                              <label>Username</label>
                              <input type="text" name="username" id="username" v-model="username" placeholder="Enter your username" class="form-control" required>
                          </div>
                          <button type="submit">LOG IN &nbsp;&nbsp;<span v-if="showSpinner" class="fa fa-spin fa-spinner"></span> </button>
                      </form>
                  </div>

                  <div class="login-image-column">
                      <div class="image-holder">
                          <img src="./../assets/logo.png" alt="">
                      </div>
                  </div>
           </div>
           </div>
        </div>
</template>

<script>
import { SignUpRequest } from '../../chat-service/auth_pb';
import { AuthServiceClient } from '../../chat-service/auth_grpc_web_pb';

const dest = process.env.VUE_APP_URL;

const authClient = new AuthServiceClient(dest);

export default {
  data() {
    return {
      username: "",
      userId: "",
      authToken: "",
      refreshToken: "",
      showSpinner: false
    };
  },
  methods: {
    authLoginUser() {
      this.showSpinner = true;

      var req = new SignUpRequest();
      req.setUserName(this.username);

      authClient.signUp(req, {}, (err, res) => {
        if (err) {
          this.showSpinner = false;
          console.log("Login failed with error:", err.code);
        } else {
          this.authToken = res.access_token;
          this.refreshToken = res.refresh_token;
          this.userId = res.user.id;
          this.showSpinner = false;
          this.$router.push({
            name: "chat"
          });
        }
      });
    }
  }
};
</script>
