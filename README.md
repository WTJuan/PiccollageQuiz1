# PiccollageQuiz1

## Quiz1 - First page
![IMG_2207](https://user-images.githubusercontent.com/9321042/113222636-03c8dd80-92ba-11eb-9785-b8009bf29145.PNG)

### Using step
* Tap Select button to selecet a video.
* Tap Select again to select second video.
* Tap Effect button to select a transition effect.
* Tap Process button to do the video merging process.
* The merged result will play in the background and store to the Photo Library.
* Tap Clear button to unselect videos and transition effect.

### Arichecture
![PiccollageQuiz1](https://user-images.githubusercontent.com/9321042/113224164-65d71200-92bd-11eb-9184-d8970808fcc4.png)

The videos will be merged in **WTVideoEditor** combine function. The editor contains two video assets an one **WTVideoTransitionEffect** instance.

When we chose the trainsiton effect item, it will send the two video assets fisrt to prepare the trainstion frame data that will be used in the merging step. 
In the preparing processing, I using **WTVideoFramCache**, which inherent the GPUImageBuffer class, to fetch out some frames in the end of first video and
in the begin of second video.!![PiccollageQuiz1_effect](https://user-images.githubusercontent.com/9321042/113226281-54443900-92c2-11eb-9ec2-47423d12c3c6.png)

The **WTVideoFramCache** will also stored the timestmp information of the feteched frame.

When **WTVideoEditor** doing the merging process, it will send the frames of the first video to the writer until the timestamp reach the begin of the trainsition time. Then it call the **WTVideoTransitionEffect**'s **mixAndFlushFrame** function to start the blending process and flush to the writer. After that, it start to process the second video but not to send the frames of the second video to the writer until the timestamp reach the end of the trainsition.

## Quiz3 - Next page
![IMG_2208](https://user-images.githubusercontent.com/9321042/113223345-8d2cdf80-92bb-11eb-9bfe-5aa9152d7ea2.PNG)

### Using step
It will do a default process for the bubble image.
* Tap Select button to select a image to do the process.

### Concept
The current pixel(p) color is combine with the green color of p1, the one time offset to p, and the blue color of p2, the two times offset to p, and p's red color.
