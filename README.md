# Chronosculpt
<img width="259" alt="main" src="https://github.com/user-attachments/assets/c6b0b7bc-1b8f-42ba-9c8b-895f250aa7d9" />

## Overview
Chronosculpt is a full-stack web &amp; mobile habit tracking app built to empower users to achieve their goals through consistent progress. It is currently deployed on the web [here](https://chronosculpt.web.app) and will soon be available on the iOS App Store.

The frontend was built using Flutter, a cross-platform application development framework in Dart. The files for the frontend are located in [the app folder](/app). The backend was primarily built using Flask, a Python backend framework, and is located in [the backend folder](/backend); authentication and user accounts were implemented using Firebase. Finally, the app stores data in a remotely deployed PostgreSQL database. 

## Major Features

### User Accounts
<img width="259" src="https://github.com/user-attachments/assets/197198b5-8b05-4c34-9ff1-c2404fc67157" />
<img width="259" src="https://github.com/user-attachments/assets/de03104c-555e-4c9b-85cf-7c7804623ff4" />

### Defining Habits
<img width="259" src="https://github.com/user-attachments/assets/67e8cfb4-715b-49bb-a547-7db4640ba7fc" />
<img width="259" src="https://github.com/user-attachments/assets/ce66097e-e687-4231-8a89-0db214ecca93" />

Habits can be defined with a name, comments, length (in minutes), and optionally a preferred quadrant for the interactive scheduler widget.

### Initializing Records
<img width="259" src="https://github.com/user-attachments/assets/a1de114e-2324-488d-9a24-89d49e86a4e5" />

Chronosculpt tracks progress by creating a "record" for each day. When the user creates a new record, all of their habits are copied as entries onto the new record.

### Current Day: Log View
<img width="259" src="https://github.com/user-attachments/assets/7044aa72-1cbd-41a7-8aa3-3880a3b880b3" />
<img width="259" src="https://github.com/user-attachments/assets/0ca6d856-8d08-43a0-bc3f-d3dc6841daa9" />

Selecting log view displays all entries for a given day. Tapping on a card creates a dialog to edit the comments for the given entry. Tapping and holding launches a stopwatch view for the entry.

#### Stopwatch
<img width="259" src="https://github.com/user-attachments/assets/20f5c6e3-3414-4b7c-9012-991176977a5a" />

Launching a stopwatch view enables users to record the time spent on a habit. Additionally, the average and personal best times are both displayed. Both saving and resetting require long presses to avoid accidental triggers.

### Current Day: Interactive Scheduler View
<img width="259" src="https://github.com/user-attachments/assets/f4286c66-55ed-4d92-8b3a-075a5b4a8337" />
<img width="259" src="https://github.com/user-attachments/assets/c9c0b23c-2744-4b08-b77d-957a40545f03" />

Selecting interactive scheduler view displays the current record in a convenient, readable format. Entries are mapped as draggable tiles that can be rearranged to schedule. For more complex planning, users can write comments for each quadrant. Entry comments and quadrant notes are displayed as tooltips when mousing over the respective elements. Additionally, tapping on an entry will either immediately mark it as done or return it to the quadrant in which it was previously scheduled and long pressing on an entry will launch a stopwatch view as in the log view.

#### Multitimer
<img width="259" src="https://github.com/user-attachments/assets/5444b06a-18b6-481c-ba25-58a4ffbc76f1" />

Long pressing on a quadrant launches a multitimer view which enables users to freely rearrange and sequentially time several habits. Like in the stopwatch view, most actions require long presses to avoid accidental triggers. 

### History
Chronosculpt offers history reporting at both the record and habit level.

#### Record History
<img width="259" src="https://github.com/user-attachments/assets/7b51c49b-e38c-429a-b3ee-8ecc678660ae" />
<img width="259" src="https://github.com/user-attachments/assets/1a18eb5a-fb71-4406-8876-e63bffe0fde3" />

All previous records are displayed along with the proportion of habits that were completed. Tapping on a given record launches a view with detailed reporting of habit activity.

#### Habit History
<img width="259" src="https://github.com/user-attachments/assets/dbc1b17e-879b-416c-9370-803664e1a8d2" />
<img width="259" src="https://github.com/user-attachments/assets/e8ddf5cb-6245-4d33-88c6-74b4802f5823" />

All previous habits are displayed along with the proportion of occurrences that were completed. Tapping on a given habit launches a view with all occurrences laid out sequentially.

### Profile Management
<img width="259" src="https://github.com/user-attachments/assets/6ab808a8-1f7e-4cf1-9ef0-f26328d05aaa" />

Users can change their email and password from the profile management page.
