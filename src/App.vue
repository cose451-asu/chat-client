<template>
  <div id="app">
    <router-view/>
  </div>
</template>

<script>
import "./App.css";

export default {
  created() {
    this.initializeApp();
  },

  methods: {
    initializeApp() {
    }
  }
};
</script>
