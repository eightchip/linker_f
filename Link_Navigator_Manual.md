# Link Navigator Manual

## Basic Information
- **App Name**: Link Navigator
- **Overview**: A desktop application that organizes files, folders, and URLs by groups, allowing intuitive management through drag & drop
- **Supported OS**: Windows 11

## Main Features
1. Group Management
2. Link Management (Files, Folders, URLs)
3. Drag & Drop Operations
4. Search Function
5. Memo Function
6. Theme Switching (Light/Dark Mode)
7. Accent Color Change
8. Data Export/Import
9. Bulk Memo Editing
10. Task Management
11. Subtask Management
12. Notification Function (with sound)
13. Keyboard Shortcuts
14. Google Calendar Integration (※ User configuration required)
15. Outlook Schedule Import
16. Schedule List (Calendar View)
17. Gmail Integration (Mailer Launch)
18. Help Center (Markdown Display / HTML Export)
19. Task Merge Function
20. Outlook Auto Import (on startup / scheduled execution)

## Screen Structure
### Link Management Screen
- **Title Bar**: "Link Navigator"
- **Action Menu**: 3-dot menu in the top right corner
- **Main Area**: Display of groups and links
- **Search Bar**: Search function (optional display)

## Screen Categories and Main Entries
| Category | Screen | Main Entry | Screenshot |
|---|---|---|---|
| Link Management | Link Management Screen | 3-dot menu in top right | [Link Management 3-dot Menu](screenshot:link-menu) |
| Task Management | Task List View (Standard/Compact) | Link Management 3-dot menu → "Task Management" | [Task Screen 3-dot Menu](screenshot:task-menu) |
| Task Management | Schedule List | Task List Screen 3-dot menu → "Schedule List" | [Schedule List](screenshot:schedule-list) |

### Demo Videos
- [Link Management: Creating New Groups and Adding Files/Folders](video:add_new_group)
- [Link Management: Moving Groups, Adding Memos, Creating New Tasks](video:new_memo_task_add)
- [Task Management: Introduction to Various Features (Compact View / Schedule List)](video:task_screen)

### Link Management Screen
- This is the main view for managing groups and links.
- Operations such as adding, settings, help, and shortcuts are performed from the **Global Menu (3-dot menu)** in the top right corner.
- Shortcuts are set for major operations such as `Ctrl+N` for adding groups and `Ctrl+F` for displaying the search bar.

#### Global Menu (3-dot Menu)
- `[View Link Management 3-dot Menu Screenshot](screenshot:link-menu)`
- **Common Menu**: Accessible from both screens
  - **Settings**: Configure various settings such as theme, color presets, and data management (`Ctrl+Shift+S`)
  - **Help Center**: Display this manual
  - **Bulk Memo Edit**: View and edit links with memos registered (`Ctrl+E`)
- **Link Management Menu**: Active on Link Management Screen
  - **Add Group**: Create a new group (`Ctrl+N`)
  - **Search**: Toggle search bar display/hide (`Ctrl+F`)
  - **Task Management**: Navigate to Task Management Screen (`Ctrl+T`)
  - **Change Group Order**: Change the order of groups (`Ctrl+O`)
  - **Shortcut Keys**: Open shortcut list dialog (same as `?` icon) (`F1`)
- **Task Management Menu**: Active on Task Management Screen (also accessible from Link Management Screen, navigates to Task Management Screen when selected)
  - **New Task**: Create a new task (`Ctrl+N`)
  - **Bulk Select Mode**: Toggle bulk select mode (`Ctrl+B`)
  - **CSV Export**: Export tasks in CSV format (`Ctrl+Shift+E`)
  - **Schedule List**: Display schedule list (`Ctrl+S`)
  - **Grouping**: Display grouping menu (`Ctrl+G`)
  - **Create from Template**: Create task from template (`Ctrl+Shift+T`)
  - **Toggle Statistics/Search Bar**: Toggle display/hide of statistics and search bar (`Ctrl+F`)

### Task Management Screen
- This is a task-focused operation area that transitions from the Link Management Screen.
- You can display a list of shortcuts with `F1` or the `?` icon in the AppBar.

#### Task List View (Standard Display)
- Displays task details in a vertical list.
- Can switch to compact view with `Ctrl+X`.
- Can switch to schedule list from the 3-dot menu in the top right.

#### Compact View
- A view that provides an overview of tasks in card format (grid). You can visually check progress and categories.
- Can switch to standard view with `Ctrl+X`.
- Can select the number of columns and toggle detailed display.

#### Schedule List
- `[View Schedule List Screenshot](screenshot:schedule-list)`
- Check schedules linked to tasks in date order. You can switch between list/weekly/monthly display from the menu in the top right of the screen.

## Basic Operations

### Creating a Group
1. Select "Add Group" from the 3-dot menu in the top right of the Link Management Screen
2. Enter the group name
3. Set color and icon as needed
4. Click "Create"

### Adding Links

#### Method 1: Manual Addition
1. Click the "+" icon of the group
2. Select link type (File/Folder/URL)
3. Enter label (display name)
4. Enter path/URL
5. Click "Add"

#### Method 2: Drag & Drop
1. Drag files/folders from Explorer
2. Drop onto the target group
3. Bookmark files (*.html) exported in HTML format from browsers can also be registered by drag & drop
   - Export procedures vary by browser, so click "[Search for Bookmark Export Methods](https://www.google.com/search?q=browser+bookmark+export+method)" to check the latest information if needed

### Link Operations

#### Launch
- Click the link

#### Edit
- Click the "Edit" icon

#### Delete
- Click the "Delete" icon

#### Add Memo
- Click the "Memo" icon

### Group Operations

#### Reorder
- Drag & drop groups to move them

#### Edit
- Click the "Edit" icon of the group

#### Delete
- Click the "Delete" icon of the group

### Moving Links
- Drag a link and drop it onto another group

## Search Function
1. Display the search bar with `Ctrl+F` or by selecting "Search" from the 3-dot menu
2. Enter keywords (searches file names, folder names, URLs, descriptions, tags)
3. Results are filtered as you type
   - Only "Title" and "Description" parts are highlighted (tags and requestors are included in results but not emphasized)

## Memo Function

### Individual Memo
1. Click the "Memo" icon of the link
2. Enter memo content
3. Click "Save"

### Bulk Memo Edit
1. Select "Bulk Memo Edit" from the 3-dot menu
2. Links with memos registered are displayed in a list
3. Edit memos for each link
4. Click "Save All"

## Theme Settings

### Light/Dark Mode Toggle
1. Open "Settings" from the 3-dot menu on the Link Management Screen
2. Toggle light/dark mode with the toggle in the "Theme" section

### Accent Color Change
1. Open "Settings" from the 3-dot menu on the Link Management Screen
2. Select a color from the "Accent Color" color palette
3. Click "Select"

### Color Presets
- Apply recommended color schemes (9 types) with one tap from "Color Presets" in the settings screen
- Presets include intensity, contrast, and dark mode recommended settings

## Data Management

### Export
1. Open "Settings" from the 3-dot menu on the Link Management Screen
2. Click "Export" in the "Data Management" section
3. Specify save location and file name, then click "Save"

### Import
1. Open "Settings" from the 3-dot menu on the Link Management Screen
2. Click "Import" in the "Data Management" section
3. Select the exported file and click "Open"
4. Specify how to merge with existing data and execute

### Backup Function
- **Auto Backup**: Checked on app startup and executed at configured intervals
- **Manual Backup**: Can be executed with the "Execute Manual Backup" button in the settings screen
- **Backup Folder**: Open the folder with the "Open Backup Folder" button in the settings screen
- **Save Location**: %APPDATA%/linker_f/backups/
- **File Format**: JSON (includes links, tasks, settings)
- **Maximum Saves**: 10 files (old ones are automatically deleted)

## Task Management Function

### Creating Tasks
1. Open "Task Management" from the 3-dot menu on the Link Management Screen
2. Click the "New Task" button in the top right of the Task Management Screen (or `Ctrl+N`)
3. Enter task information (title, description, due date, priority, etc.)
4. Click "Create"

### Task Operations
- **Edit**: Click task to edit
- **Delete**: Delete from task's 3-dot menu (completed tasks can also be deleted)
- **Status Change**: Not Started → In Progress → Completed
- **Priority Setting**: Low, Medium, High, Urgent (displayed with color icon + text)
- **Pin**: Pin task to display at the top
- **Bulk Operations**: Select multiple tasks to delete, change status, or change priority in bulk
- **Grouping**: Group display by due date, tags, links, status, priority
- **Filter**: Filter by status, priority, tags, due date color
- **Search**: Search by task title, description, tags (highlighted display)

### Task Merge Function

#### Function Overview
- Function to merge multiple tasks into one task
- Merges schedules, subtasks, memos, links, and tags from source tasks
- Automatically selects more important values for priority, due date, and reminder

#### How to Merge Tasks
1. Enable bulk select mode on the Task Management Screen (`Ctrl+B`)
2. Select multiple tasks to merge (at least 2)
3. Click the "Merge" button at the top of the screen
4. Select the target task for merging (select from list in dialog)
5. Confirm the content in the confirmation dialog and click "Merge"

#### Merge Behavior
- **Merged Information**:
  - Schedules (ScheduleItem): Schedules from source tasks are moved to the target task
  - Subtasks: Subtasks from source tasks are moved to the target task
  - Memos (notes): Memos from each task are merged with separator (`---`)
  - Description: Descriptions from each task are merged with separator
  - Assignee (assignedTo): Assignee information from each task is merged with separator
  - Links (relatedLinkIds): Links from source tasks are merged to the target task (duplicates removed)
  - Tags (tags): Tags from source tasks are merged to the target task (duplicates removed)
- **Automatically Selected Values**:
  - **Priority**: Higher priority is preferred (Urgent > High > Medium > Low)
  - **Due Date**: Earlier due date is preferred
  - **Reminder**: Earlier reminder time is preferred
- **Source Task Processing**:
  - By default, changed to "Completed" status (not deleted)
  - Schedules and subtasks from source tasks are moved to the target task
- **Completion Notification**: When merge is complete, the number of merged tasks is displayed

### CSV Export Function

#### Function Overview
- Export task data in CSV format
- Outputs filtered tasks and completed tasks
- Can select columns to output

#### Export Method
1. Open the 3-dot menu on the Task Management Screen (or `Ctrl+Shift+E`)
2. Select "CSV Export"
3. Select columns to output (select with checkboxes)
4. Specify save location and click "Save"

#### Export Content
- **Filtered Tasks**: Tasks matching current filter conditions
- **Completed Tasks**: Tasks with "Completed" status are automatically included
- **Selectable Columns**: ID, Title, Description, Due Date, Reminder Time, Priority, Status, Tags, Related Link IDs, Created Date, Completed Date, Started Date, Completed Date (manual input), Estimated Time, Memo, Recurring Task, Subtask Information, etc.

#### Notes
- Export file is saved to Desktop (default)
- File name is automatically generated in `tasks_export_YYMMDD_HHmm.csv` format
- Output with BOM (Byte Order Mark) so Japanese characters display correctly in Excel

### Task Sorting
- **By Due Date**: Display in ascending order of due date (no due date is last)
- **By Priority**: Display in order of urgency
- **By Title**: Display in alphabetical order
- **By Created Date**: Display in order of newest creation date
- **By Status**: Display in order of Not Started → In Progress → Completed
- **Manual Adjustment**: Long press the drag handle (⋮⋮) at the right edge of each card and drag up/down → Change to any order (click to edit)
- **Multiple Conditions**: Can set up to 1st, 2nd, and 3rd priorities

### Subtask Management Function
- **Add Subtask**: Click the subtask icon of the task
- **Edit Subtask**: Detailed editing in subtask dialog
- **Progress Display**: Badge display of completed/total count
- **Estimated Time**: Set estimated time for each subtask
- **Memo Function**: Add memo for each subtask

### Reminder Function
- When a due date is set for a task, a reminder is automatically set
- Desktop notification with sound displays the reminder
- Can set recurring reminders (daily, weekly, monthly, etc.)

### Task and Link Integration
- Can associate links with tasks
- Link reordering (drag & drop)
- Display link memo content on task card hover
- Link favicon display (URL uses fallback favicon)
※ Enter the URL of the icon you actually want to display for the fallback favicon

## Google Calendar Integration Function

### Integration Settings
- **Important**: Disabled by default. To use Google Calendar integration, users must create an OAuth client in Google Cloud Console and register credentials in the settings screen.
1. Open the "Google Calendar" section in the settings screen
2. Enter the obtained client ID/secret and execute authentication
3. Set auto sync interval (in minutes)

### Sync Function
- **Full Sync**: Bidirectional sync between app and Google Calendar
- **Holiday Exclusion**: Holiday events are automatically excluded
- **Duplicate Prevention**: Prevents duplicate creation of the same task
- **Auto Sync on Startup**: Auto sync when app starts

### Sync Content
- **App → Google Calendar**: Create tasks as calendar events
- **Google Calendar → App**: Get calendar events as tasks
- **Holiday Exclusion**: Holiday-related events are excluded from sync
- **Schedule Sync**: Schedules in the schedule list are also automatically synced to Google Calendar

## Outlook Schedule Import Function

### Function Overview
- Automatically retrieve schedules from Outlook calendar
- Associate tasks with schedules
- Automatically detect and update schedule changes
- Auto import function (on startup / scheduled execution)

### Outlook Auto Import Function

#### Setup Method
1. Open the "Outlook Auto Import" section in the settings screen
2. Turn on "Enable Outlook Auto Import"
3. Set import period (default: 30 days)
4. Select import frequency:
   - **On Startup Only**: Execute once when app starts
   - **Every 30 Minutes**: Auto execute at 30-minute intervals
   - **Every 1 Hour**: Auto execute at 1-hour intervals
   - **Daily at 9:00 AM**: Auto execute daily at 9:00 AM

#### Behavior
- **Import Period**: Retrieve schedules from tomorrow to the set number of days later
- **Duplicate Check**: Already imported schedules are automatically skipped
- **Dedicated Task**: Auto-imported schedules are assigned to a dedicated task
- **Completion Notification**: Display message when import is complete (number added / number skipped)
- **Error Handling**: Automatically skip if Outlook is unavailable
- **PowerShell Script Externalization**: Outlook calendar schedule retrieval is executed using an external PowerShell script (`get_calendar_events.ps1`)
  - Script is placed in `%APPDATA%\Apps\`
  - Using external script prevents Outlook crashes
  - Falls back to inline script if script does not exist

#### Notes
- Outlook must be running
- **⚠️ Warning: Outlook that is running may crash when auto import is executed**
- Auto import does not import schedule body (only date/time and title)
- Already imported schedules are not re-imported due to duplicate check
- Outlook calendar schedule retrieval function uses an external PowerShell script (`get_calendar_events.ps1`)
  - Script can be checked in the "Outlook Integration" section of the settings screen
  - Schedule retrieval may fail if script is not properly placed

### Schedule Import Method (Manual)

#### Method 1: From Task Edit Modal
1. Open the task edit modal
2. Click "Import Schedules from Outlook" button
3. Select period (default: tomorrow to 1 month)
4. Click "Get Schedules" button
5. Select schedules to import
6. Assign to existing task or create new task

#### Method 2: Bulk Import from Schedule List
1. Click "Import Schedules from Outlook" button on the schedule list screen
2. Select period (can set start date and end date individually)
3. Click "Get Schedules" button
4. Retrieve and match schedules asynchronously (display message and animation)
5. Display only schedules with changes or not yet imported
6. Narrow down schedules with search and sort functions
7. Select schedules with checkboxes
8. Click "Assign to Task" or "Create New Task"

### Matching Function
- **Existing Schedule Detection**: Identify already imported schedules with `outlookEntryId`
- **Change Detection**: Automatically detect time and location changes
- **Completed Task Exclusion**: Schedules related to completed tasks are excluded
- **Duplicate Prevention**: Do not display already imported schedules (only display if there are changes)

### Display Function
- **Schedules without Location**: Schedules without location specified are also displayed
- **Sort**: Title ascending → Date/time ascending, or date/time ascending
- **Search**: Search by schedule title and location

## Schedule List (Calendar View) Function

### Function Overview
- Display schedules associated with tasks in a list
- Organized display by date
- Schedule edit, delete, and copy functions
- Can directly add and edit schedules from task edit modal

### Schedule Add/Edit Method

#### From Task Edit Modal
1. Click task to open edit modal
2. Expand "Schedule" section (collapsible)
3. Click "Add Schedule" button
4. Enter schedule information:
   - **Title**: Schedule title (task name is entered by default)
   - **Start Date/Time**: Select date and time
   - **End Date/Time**: Select if there is an end time (optional)
   - **Location**: Meeting location, etc. (optional)
   - **Memo**: Additional information (optional)
5. Click "Add"
6. To edit an existing schedule, click the "Edit" icon of the schedule item
7. To delete a schedule, click the "Delete" icon of the schedule item
8. To copy a schedule, click the "Copy" icon of the schedule item (duplicate to the same task)

#### From Schedule List Screen
1. Open the schedule list screen (`Ctrl+S`)
2. Click FAB button (+ button in bottom right)
3. Select task and add schedule

### Schedule List Display
1. Open "Schedule List" from the home screen sidebar
2. Schedules are displayed by date
3. Only schedules from today onward are displayed by default
4. Can also display past schedules with "Show Past" checkbox
5. Can select the following from "View Switch" menu in the top right
   - **List View**: Display schedule cards by date (default)
   - **Monthly View**: Display schedules for each day in monthly format (date/time + title only)
     - In monthly view, a button to export to Excel in bulk is displayed
     - Excel export outputs in 1-cell format with dates and schedules listed

### Schedule Operations
- **Add**: Add schedule with FAB button
- **Edit**: Long press schedule and select edit from menu
- **Delete**: Long press schedule and select delete from menu
- **Copy**: Copy schedule for the same task (for recurring meetings)
- **Access to Task**: Click schedule to open related task's edit modal

### Filter Function
- **Task Filter**: Display only schedules for specific tasks (only incomplete tasks displayed)
- **Date Range Filter**: Filter by specifying start date and end date
- **Past/Future Filter**: Toggle with "Show Past" checkbox
- **Search**: Search by schedule title, task name, location, memo (highlighted display)

### Excel Copy Function
1. Select dates to copy with date checkboxes
2. Select all/deselect all with bulk select button
3. Select format from Excel copy button
   - **Table Format (Multiple Columns)**: Expand to multiple columns with tab separation
   - **1-Cell Format (List)**: Paste in list format in 1 cell

### Schedule Display Content
- **Date/Time**: Start time, end time (only start time if no end time)
- **Location**: Displayed if location is set
- **Title**: Schedule title
- **Task Name**: Related task name (clickable)
- **Memo**: Collapsible display if memo exists (closed by default)
- **Past Schedules**: Past schedules are displayed in gray

### Reminder Function
- Display popup modal 15 minutes before schedule time (Outlook style)
- Desktop notification with sound

### Jump to "Today"
- When schedule list is opened, automatically scroll to today's position

## Gmail Integration Function

### Function Overview
- Launch Gmail mailer from task edit modal
- No API or access token required
- Records email send history

### How to Use
1. Open task edit modal
2. Click "Send with Gmail" button
3. Gmail mailer launches
4. After sending email, send history is recorded

### Settings
- Check description in "Gmail Integration" section of settings screen
- Connection test function available

## Help Center
- Launch from global menu (3-dot menu) on Link Management Screen / Task Management Screen
- Quickly navigate to desired items with heading list (table of contents) and keyword search
- "Export HTML / Print" button displays content in browser, allowing direct printing or PDF saving
- Clicking "View Screenshot" links in the manual displays images placed in the `assets/help/` folder in a popup (please place image files as needed for your purposes)
- Clicking "View Video" links plays MP4 files placed in `assets/help/videos/` within the app (warning is displayed if file does not exist).

## Notification Function

### Notification Settings
- Set notification display/hide in settings screen
- Set notification sound on/off
- Can test notification sound

### Notification Types
- Task reminder notification
- Overdue task notification
- Test notification

## How to Create Demo Videos
1. **Record**  
   - Use Windows 11 standard *Xbox Game Bar* (`Win + G`) → "Capture" widget → Press "Start Recording"  
   - Or use any recording software such as Clipchamp / OBS Studio
2. **Edit (Optional)**  
   - Trimming unnecessary parts and adding subtitles and highlights improves visibility
3. **Export**  
   - MP4 (H.264 + AAC) format, resolution 1920x1080 / 60fps or less recommended  
   - File size of about 50MB or less is stable for loading
4. **Place**  
   - Save in `assets/help/videos/` folder with the following names  
     - `demo_link.mp4` … Link Management Screen demo  
     - `demo_task.mp4` … Task Management Screen demo  
     - `demo_schedule.mp4` … Schedule List demo  
   - To use different names, edit `_videoMap` in `lib/views/help_center_screen.dart`
5. **Build**  
   - `flutter pub get` → `flutter build windows` (or `flutter run`) to rebuild, then playable from Help Center

## Keyboard Shortcuts

### Link Management Screen
| Key | Function | Description |
|------|------|------|
| Ctrl+N | Add Group | Create a new group |
| Ctrl+F | Show Search Bar | Open search bar and focus |
| Ctrl+E | Bulk Memo Edit | Display bulk memo edit dialog |
| Ctrl+O | Change Group Order | Display change group order dialog |
| Ctrl+T | Task Management | Open Task Management Screen |
| Ctrl+Shift+S | Settings Screen | Open settings screen |
| F1 | Shortcut Help | Display list of shortcut keys |
| → | Global Menu | Open global menu (3-dot) in top right |
| Escape | Close Search Bar | Close search bar |
| Tab | Toggle Tag Selection | Switch link type filter |
| ← | Go Back | Return to Link Screen from Task Management Screen / Settings Screen |

### Task Management Screen
| Key | Function | Description |
|------|------|------|
| Ctrl+T | Task Management | Open Task Management Screen (from Link Management Screen) |
| Ctrl+F | Toggle Statistics/Search Bar | Toggle display/hide of statistics and search bar |
| Ctrl+G | Grouping Menu | Display grouping menu |
| Ctrl+S | Open Schedule List | Display schedule list |
| Ctrl+N | New Task | Create a new task |
| Ctrl+B | Toggle Bulk Select Mode | Toggle bulk select mode |
| Ctrl+Shift+E | CSV Export | Export tasks in CSV format |
| Ctrl+Shift+S | Settings Screen | Open settings screen |
| Ctrl+Shift+T | Create from Template | Create task from template |
| Ctrl+Z | Toggle Detail Display | Toggle display/hide of all task details in bulk |
| Ctrl+X | Toggle Compact ⇔ Standard View | Toggle between compact view and standard view |
| ← | Go Back | Return to Link Management Screen |
| → | Global Menu | Open global menu (3-dot) |
| ↓ | Focus on Global Menu | Move focus to global menu |
| F1 | Shortcut Help | Display list of shortcut keys |
| Escape | Close Dialog | Close open dialog |

## Troubleshooting

### Common Problems and Solutions

#### Q: Links don't open
**A:**
- Check if file/folder path is correct
- Check if file/folder exists
- Check if URL format is correct

#### Q: Drag & Drop doesn't work
**A:**
- Run app with administrator privileges
- Check antivirus software settings
- Check file/folder access permissions

#### Q: Data disappeared
**A:**
- Restore from exported backup file
- Try restarting the app
- Check settings file

#### Q: App won't start
**A:**
- Run with administrator privileges
- Check if required runtime is installed
- Antivirus software exclusion settings

#### Q: Notification sound doesn't play
**A:**
- Check Windows system sound settings
- Check system volume settings
- Check if notification sound is enabled in settings screen
- Test with notification sound test button

## Support Information
- **App Name**: Link Navigator
- **Supported OS**: Windows 11
- **Required Environment**: .NET Framework 4.7 or higher (recommended)

## Update History
- Initial Version: Basic functions implemented
- Search function added
- Memo function added
- Theme switching function added
- Data export/import function added
- Task management function added
- Subtask management function added
- Notification function (with sound) added
- Keyboard shortcut function added
- Back shortcut from settings screen added
- Google Calendar integration function added
- Holiday task auto exclusion function added
- Task duplicate prevention function added
- Outlook schedule import function added
- Schedule List (Calendar View) function added
- Gmail integration function added (mailer launch)
- Help Center (search / HTML export) added
- Task Management Screen improvements (grouping, bulk operations, enhanced filters)
- Color icons added to priority filter
- Schedule Google Calendar auto sync function added
- Schedule reminder function added (15-minute advance notification)
- Excel copy function added (table format / 1-cell format)
- Task merge function added (merge multiple tasks)
- Outlook auto import function added (on startup / scheduled execution)
- Schedule add/edit function from task edit modal added
- CSV export function to include completed tasks added
- Message display unified to center snackbar (resolved scroll cutoff issue at bottom of screen)
- Global menu implemented (integrated common menu, link management menu, task management menu)
- Outlook calendar schedule retrieval PowerShell script externalized (`get_calendar_events.ps1`)
- Schedule list weekly view removed, monthly view Excel bulk export function added
- Card view night mode support (title displayed in white text)
- Shortcut key processing improvements (implementation independent of focus)

**Notes**
- It is recommended to regularly back up data
- Export data before updating the app
- Notification sound depends on Windows system sound settings
- Google Calendar integration can only be used if the user has completed API setup and authentication (disabled by default)
- Outlook must be running to use Outlook schedule import function

