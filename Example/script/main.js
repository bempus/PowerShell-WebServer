console.log("Hello from main.js");
// This file can be placed anywhere, even in the Pages or API folders, for convienience it's placed in its own folder

document.querySelector("#clickme").addEventListener("click", (e) => {
  fetch("/api/show-message", {
    method: "POST",
    body: JSON.stringify({
      message: "Hello from Webserver!",
      title: "API",
    }),
  });
});
