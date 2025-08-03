# 🎯 **PopStash Premium MenuBarExtra Experience - Master Plan**

## 🏗️ **Core Architecture & Navigation Structure**

### **MenuBarExtra Main Popover**
```
┌─────────────────────────────────────┐
│ [📋 5] PopStash        [⚙️] [📊] [×] │ <- Dynamic count, preferences, analytics, close
├─────────────────────────────────────┤
│ 🔍 Search clipboard...              │ <- Live search with debounced filtering
├─────────────────────────────────────┤
│                                     │
│ [Clipboard Timeline - Main View]    │
│                                     │
└─────────────────────────────────────┘
```

**Navigation Structure:**
- **Main Popover**: Clipboard timeline (default view)
- **⚙️ Button**: Opens **separate Preferences window** (not a subpane)
- **📊 Button**: Opens **Analytics pane within the popover** (NavigationStack destination)

### **Window/View Hierarchy**
```
PopStash App
├── MenuBarExtra Popover (320-480w, 400-800h, resizable)
│   ├── Main View: Clipboard Timeline
│   ├── Analytics View: (NavigationStack destination)
│   └── Search/Filter Overlay
├── Preferences Window (separate, 600x500, fixed)
│   ├── General Tab
│   ├── Privacy Tab  
│   ├── Advanced Tab
│   └── About Tab
└── Notification Popup Window (small, auto-positioning)
```

---

## 🎨 **MenuBarExtra Popover - Main Interface**

### **Dynamic Menu Bar Icon System**
**Location**: Menu bar system tray
- **Empty state**: Outline clipboard icon
- **1-9 items**: Filled icon + small badge number
- **10+ items**: Filled icon + "9+" badge
- **Active copying**: Brief pulse animation
- **Error state**: Red dot indicator
- **Sync state**: Rotating activity indicator (future feature)

### **Popover Header Toolbar**
**Location**: Top of popover, always visible
```
┌─────────────────────────────────────┐
│ [📋 5] PopStash        [⚙️] [📊] [×] │
└─────────────────────────────────────┘
```
- **Left**: App name + dynamic clipboard count
- **Right**: Preferences button, Analytics button, Close button
- **Background**: Translucent material with subtle blur

### **Search Bar**
**Location**: Below header, collapsible
- **Default**: Collapsed, shows "🔍 Search" button
- **Active**: Expands to full-width search field
- **Features**: Live filtering, content type filters, time range
- **Keyboard**: ⌘K to focus

### **Main Content Area: Clipboard Timeline**
**Location**: Primary popover content, scrollable
- **Layout**: Vertical list with time-based grouping
- **Groups**: "Just now", "Today", "Yesterday", "This week", "Older"
- **Item cards**: Rich previews with hover effects
- **Actions**: Pin button, copy button, delete button per item
- **Empty state**: Helpful onboarding message

---

## 📊 **Analytics Pane (Within Popover)**

### **Navigation Method**
**Trigger**: Click 📊 button in popover header
**Behavior**: NavigationStack pushes Analytics view within same popover
**Back Navigation**: Standard back button or swipe gesture

### **Analytics Content Areas**

#### **Usage Overview Section**
**Location**: Top of analytics view
- **Time selector**: 7 days | 30 days | All time (segmented control)
- **Key metrics cards**: Total items, Most active day, Average per day
- **Activity graph**: Line chart showing daily clipboard activity

#### **Content Breakdown Section**  
**Location**: Middle section
- **Pie chart**: Text (60%), Images (25%), Links (10%), Code (5%)
- **Content type list**: Expandable list with counts and percentages
- **Rich previews**: Sample of most common content types

#### **Usage Patterns Section**
**Location**: Lower section  
- **Peak times heatmap**: 24-hour grid showing activity patterns
- **Most copied items**: Frequency leaderboard (anonymized/truncated)
- **Source apps**: Which apps generate most clipboard activity

#### **Export Section**
**Location**: Bottom of analytics view
- **Export button**: "Export Analytics Data"
- **Format options**: JSON, CSV options in action sheet
- **Date range selector**: For export scope

---

## ⚙️ **Preferences Window (Separate Window)**

### **Window Specifications**
**Trigger**: Click ⚙️ button in popover (popover stays open)
**Window type**: Standard macOS window, 600x500px, not resizable
**Position**: Center of screen, remember last position
**Behavior**: Can coexist with open popover

### **Tab Structure**

#### **General Tab**
- **History Settings**: Item limit (50/100/200/Unlimited radio buttons)
- **Appearance**: Theme selection (Auto/Light/Dark)
- **Launch Settings**: "Launch at login" toggle
- **Menu Bar**: "Show in menu bar" toggle + icon options

#### **Privacy Tab**  
- **Content Filtering**: Sensitive data detection toggles
- **History Management**: Auto-clear options, secure delete
- **Analytics**: "Enable usage analytics" toggle
- **Data Export**: Manual export, data location info

#### **Advanced Tab**
- **Keyboard Shortcuts**: Custom shortcut recorder
- **Performance**: Memory usage limits, background behavior
- **Debug**: Logging level, crash reporting
- **Experimental**: Beta feature toggles

#### **About Tab**
- **App info**: Version, build, system requirements
- **Credits**: Developer info, acknowledgments
- **Support**: Help links, feedback options
- **License**: Open source license info

---

## ⚡ **Advanced Features & Interactions**

### **Smart Content Recognition**
**Location**: Applied to all clipboard items in timeline
- **URLs**: Rich link previews with favicon + title
- **Images**: Thumbnail previews with zoom on hover
- **Code**: Syntax highlighting + language detection
- **Files**: File type icons + metadata display
- **Colors**: Color swatches for hex/rgb values
- **JSON/XML**: Collapsible tree structure

### **Pin System**
**Location**: Throughout clipboard timeline
- **Pin button**: Star icon on each item card
- **Pinned section**: Top of timeline, separate from time groups
- **Visual distinction**: Different background color/border
- **Persistence**: Pinned items survive history cleanup

### **Keyboard Shortcuts**
**Global shortcuts**:
- **⌘⇧V**: Toggle popover open/close
- **⌘⇧C**: Show notifications for new clipboard item

**Within popover**:
- **⌘K**: Focus search
- **↑↓**: Navigate items
- **⏎**: Copy selected item  
- **⌘1-9**: Quick copy recent items
- **⌘⌫**: Delete selected item
- **⌘A**: Select all visible
- **Esc**: Close popover

### **Export System**
**Location**: Analytics pane + context menus
- **Individual items**: Right-click → "Export item"
- **Selected items**: Multi-select → "Export selected"  
- **Full history**: Analytics pane → "Export all data"
- **Formats**: JSON (structured), CSV (tabular), TXT (plain)
- **Naming**: Auto-generated with timestamps

---

## 🎯 **User Experience Flow Examples**

### **Typical Usage Flow**
1. **Copy something** → Notification popup appears briefly
2. **Click menu bar icon** → Popover opens to timeline
3. **Browse recent items** → Hover for previews, click to copy
4. **Search for older item** → ⌘K → type → select → copy
5. **Pin important item** → Click star → moves to pinned section
6. **Check usage stats** → Click 📊 → view analytics → back to timeline

### **Configuration Flow**
1. **Open preferences** → Click ⚙️ → separate window opens  
2. **Adjust settings** → Change history limit, theme, shortcuts
3. **Close preferences** → Settings auto-save, window closes
4. **Continue using** → Popover still open, settings applied

### **Analytics Review Flow**
1. **View analytics** → Click 📊 in popover
2. **Explore data** → Switch time ranges, examine patterns
3. **Export insights** → Select format, choose date range
4. **Return to timeline** → Back button or navigation

---

## 🚀 **Implementation Phases**

### **Phase 1: Core Structure**
- Fix navigation stack in popover
- Implement dynamic menu bar icon with count
- Create header toolbar with working buttons
- Set up separate preferences window
- Basic analytics view framework

### **Phase 2: Rich Content**
- Smart content recognition and previews
- Pin/unpin functionality with persistence
- Advanced search with filtering
- Smooth animations and transitions

### **Phase 3: Intelligence**
- Complete analytics dashboard with charts
- Export functionality for all data types
- Keyboard shortcuts system
- Usage pattern analysis

### **Phase 4: Polish**
- Accessibility improvements
- Performance optimizations
- Advanced preferences options
- Refined micro-interactions

---

This structure maintains clear separation between the always-accessible popover (timeline + analytics) and the configuration-focused preferences window, while providing rich functionality in each area without overwhelming the user interface.