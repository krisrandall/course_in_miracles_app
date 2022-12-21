

// This should be run on this page (or similar) : https://acim.org/acim/lesson-341/i-can-attack-but-my-own-sinlessness-and-it-is-only/en/s/765?wid=toc
// Expand out all the lessons so that the links are available to scrape

// The final JSON needs escape tags stripped from it


function getLinks() {
    // Find all the anchor tags on the page with the data-testid attribute set to "AppLink"
    const anchorTags = document.querySelectorAll("a[data-testid='AppLink']");
  
    // Create an empty array to store the link objects
    const linkObjects = [];
  
    // Loop through the anchor tags
    for (let i = 0; i < anchorTags.length; i++) {
      // Get the href value for the current anchor tag
      const link = anchorTags[i].href;
  
      // Get the lesson number for the current anchor tag, or an empty string if it is not found
      let lessonNumber = anchorTags[i].querySelector(".text-start");
      lessonNumber = lessonNumber ? lessonNumber.textContent.trim() : "";
  
      // If the lesson number is not an empty string, get the lesson title for the current anchor tag
      let lessonTitle = "";
      if (lessonNumber) {
        lessonTitle = anchorTags[i].querySelectorAll("span")[1];
        lessonTitle = lessonTitle ? lessonTitle.textContent.trim() : "";
      }
  
      // If the lesson number is not an empty string, create a link object with the link, lesson number, and lesson title
      if (lessonNumber) {
        const linkObject = {
          link,
          lessonNumber,
          lessonTitle
        };
  
        // Add the link object to the array
        linkObjects.push(linkObject);
      }
    }
  
    // Return the array of link objects
    return linkObjects;
  }


// Browse to each page in the links array and fetch specific elements from the page
async function getLessonData(links) {
    // Create an empty array to store the lesson objects
    const lessonObjects = [];
    
    // Loop through the links array
    for (let i = 0; i < links.length; i++) {
        // Get the link from the current link object
        const link = links[i].link;
    
        // Get the lesson number from the current link object
        const lessonNumber = links[i].lessonNumber;
    
        // Get the lesson title from the current link object
        const lessonTitle = links[i].lessonTitle;
    
        // Navigate to the page 
  // Send a request to the specified URL and get the HTML as a response
  const response = await fetch(link);
  const html = await response.text();

  // Use the DOMParser to parse the HTML into a DOM
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, "text/html");
    
        // Get the lesson content element
        var lessonText = doc.querySelector("input#inlineSectionVM").value.replace(/&quot;/g, '"')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/<br>/g, '\n')
        .replace(/<br\/>/g, '\n');;
        
        var theObject = (JSON.parse(lessonText.replace(/(\r\n|\n|\r)/gm, "")));
        // lessonText is JSON , extract out just the bodyHtml property as the value to use - also strip newlines to make valid before parsing, and then just get the bodyHtml property
        lessonText = (theObject.bodyHtml.toString().replace(/\\"/g, '"')).replace(/\\"/g, '"'); //  I don't know why I can't get rid of the fucking escape characters

        const fullTitle = theObject.titleInfo.title;

        // makes another request to a URL like https://acim.org/we-api/en/audio/495?v=64626d86c3fc9ccd54c5ad20ce33b207 to get the audio URL
        const audioUrl = "https://acim.org/we-api/en/audio/" + theObject.sectionId + "?v=" + doc.querySelector('#htmlAssetCacheVersion').value;
      
        const audioResponse = await fetch(audioUrl);
        const audio = JSON.parse(await audioResponse.text()).media[0].url;

        
        console.log('-------------');
        console.log((lessonText));
        console.log('-------------');
        console.log(lessonText.lessonTitle);
        console.log('-------------');
        console.log(audio);
        console.log('-------------');
        console.log(doc);
        console.log('-------------');

    
        // Create a lesson object with the lesson number, lesson title, and lesson content HTML
        const lessonObject = {
        lessonShortTitle : links[i].lessonTitle,
        lessonNumber,
        lessonTitle,
        lessonText,
        fullTitle,
        audio,
        link
        };
    
        // Add the lesson object to the array
        lessonObjects.push(lessonObject);
        console.log(i + " of " + links.length + " : " + JSON.stringify(lessonObject));
    }
    
    // Return the array of lesson objects
    return lessonObjects;
}


var i = 0;
var newLinks = getLinks();

// Run the script to get the links, and then get the detailed data, and give a counter to show progress
async function run() {
    const lessonObjects = await getLessonData(newLinks); //.splice(0,1));
    console.log("Done");
    console.log(lessonObjects);
}

// Run the script
run();
