# Flodo AI Task Management App

A full-stack, cross-platform task management application built with a **Python/FastAPI** backend and a **Flutter** frontend. 

## Video Demonstration
🎥 **[Link to 1-Minute Demo Video Here]**
*(The video demonstrates core CRUD functionality, the stretch goals, and highlights a key technical decision behind the architecture.)*

---

## Track & Stretch Goals
**Track Chosen:** Full-Stack Track 

**Stretch Goals Completed:**
1. **Debounced Search with Highlighting:** The search bar strategically waits 300ms before querying the network to prevent excessive backend calls. Matching search text is instantly highlighted within the UI task cards.
2. **Recurring Task Logic & Dependencies:** 
   - Tasks can be assigned as `Daily` or `Weekly`. When marked 'Done', the backend automatically spawns the next occurrence in the future.
   - Tasks can be 'Blocked By' another task, showing up as semi-transparent with a lock icon, preventing accidental modification until the blocker is completed.
3. **Optimistic Drag-and-Drop Reordering:** Utilizing Flutter's state management to instantly and seamlessly reorganize the UI when dragging tasks, while syncing the new sort order via the backend's `/tasks/reorder` endpoint behind the scenes.
4. **Resilient Local Drafts:** If you exit the new task screen before finishing, your typed text and selected dates are preserved locally using SharedPreferences.

---

## Setup Instructions

### Prerequisites
- [Python 3.9+](https://www.python.org/downloads/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- Android Studio, Xcode, or a connected physical/web device for mobile testing

### 1. Running the Backend (FastAPI)
Open a terminal and navigate to the backend directory:
```bash
cd backend
```
*(Optional but recommended)* Create and activate a virtual environment:
```bash
python -m venv venv

# Windows:
venv\Scripts\activate
# Mac/Linux:
source venv/bin/activate
```

Install the required dependencies:
```bash
pip install -r requirements.txt
```

Start the FastAPI server:
```bash
uvicorn main:app --reload
```
The API is now running locally at `http://127.0.0.1:8000`. You can view and test the interactive API documentation at `http://127.0.0.1:8000/docs`.

### 2. Running the Frontend (Flutter)
Open a new terminal and navigate to the flutter project directory:
```bash
cd frontend/task_manager
```
Install Flutter packages:
```bash
flutter pub get
```
Run the application (select your preferred emulator or connected device):
```bash
flutter run
```

*Note on Emulators: Based on your API Service file (`lib/services/api_service.dart`), the backend baseUrl defaults to `http://127.0.0.1:8000`. If you are specifically testing via an Android Emulator, you may need to permanently update this URL inside the dart file to `http://10.0.2.2:8000` to properly map to the localhost of your machine.*

---

## AI Usage Report
Throughout the rapid development of this full-stack application, an AI coding assistant (Google Deepmind / Gemini) was leveraged to responsibly accelerate the project. Key areas where AI proved useful include:
- **Architectural Scaffolding:** Generated boilerplate SQLAlchemy syntax for the `tasks.db` schema mapping, saving setup time.
- **Bug Resolution:** Acted as a pair-programmer to isolate and solve a tricky runtime error involving Flutter's `DropdownButtonFormField` when dealing with nullable dependencies ("Blocked By" fields).
- **Optimization Algorithms:** Aided in mathematically structuring the debouncer logic (Timer) and provided the RegEx necessary for real-time text highlighting within the `TaskCard` UI widget.
- **State Management:** Clarified best practices on configuring the `Provider` layer to process optimistic networking (e.g. updating the GUI lists instantly right before confirming the `http.delete` signal).
