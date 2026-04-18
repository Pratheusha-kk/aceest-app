from flask import Flask, abort, jsonify, render_template, request

app = Flask(__name__)

PROGRAMS = {
    "Fat Loss (FL)": {
        "description": "Fat loss program",
        "workout": (
            "Mon: Back Squat 5x5 + Core\n"
            "Tue: EMOM 20min Assault Bike\n"
            "Wed: Bench Press + 21-15-9\n"
            "Thu: Deadlift + Box Jumps\n"
            "Fri: Zone 2 Cardio 30min"
        ),
        "diet": (
            "Breakfast: Egg Whites + Oats\n"
            "Lunch: Grilled Chicken + Brown Rice\n"
            "Dinner: Fish Curry + Millet Roti\n"
            "Target: ~2000 kcal"
        ),
        "color": "#e74c3c",
        "calorie_factor": 22,
    },
    "Muscle Gain (MG)": {
        "description": "Muscle gain program",
        "workout": (
            "Mon: Squat 5x5\n"
            "Tue: Bench 5x5\n"
            "Wed: Deadlift 4x6\n"
            "Thu: Front Squat 4x8\n"
            "Fri: Incline Press 4x10\n"
            "Sat: Barbell Rows 4x10"
        ),
        "diet": (
            "Breakfast: Eggs + Peanut Butter Oats\n"
            "Lunch: Chicken Biryani\n"
            "Dinner: Mutton Curry + Rice\n"
            "Target: ~3200 kcal"
        ),
        "color": "#2ecc71",
        "calorie_factor": 35,
    },
    "Beginner (BG)": {
        "description": "Beginner program",
        "workout": (
            "Full Body Circuit:\n"
            "- Air Squats\n"
            "- Ring Rows\n"
            "- Push-ups\n"
            "Focus: Technique & Consistency"
        ),
        "diet": (
            "Balanced Tamil Meals\n"
            "Idli / Dosa / Rice + Dal\n"
            "Protein Target: 120g/day"
        ),
        "color": "#3498db",
        "calorie_factor": 26,
    },
}


def estimate_program_calories(program_name: str, weight_kg: float) -> dict:
    return {
        "program": program_name,
        "weight_kg": weight_kg,
        "calorie_factor": PROGRAMS[program_name]["calorie_factor"],
        "calories_kcal": int(weight_kg * PROGRAMS[program_name]["calorie_factor"]),
    }


@app.route("/")
def index():
    return jsonify({"message": "ACEest Fitness & Gym API is running"})


@app.route("/health")
def health():
    return jsonify({"status": "healthy"}), 200


@app.route("/gui")
def gui_home():
    return render_template("index.html")


@app.route("/gui/programs")
def gui_programs():
    return render_template("programs.html", programs=PROGRAMS)


@app.route("/gui/programs/<path:program_name>")
def gui_program_detail(program_name: str):
    if program_name not in PROGRAMS:
        abort(404, description="Unknown program")
    return render_template(
        "program_detail.html",
        program_name=program_name,
        program=PROGRAMS[program_name],
    )


@app.route("/gui/calories")
def gui_calorie_estimator():
    selected_program = request.args.get("program", type=str)
    weight_kg = request.args.get("weight_kg", type=float)

    error = None
    result = None

    if selected_program and weight_kg is not None:
        try:
            if selected_program not in PROGRAMS:
                raise ValueError("Unknown program")
            if weight_kg <= 0:
                raise ValueError("Weight must be > 0")

            result = estimate_program_calories(selected_program, weight_kg)
        except ValueError as exc:
            error = str(exc)

    program_options = [
        {"name": name, "selected": name == selected_program}
        for name in PROGRAMS.keys()
    ]

    return render_template(
        "calories.html",
        program_options=program_options,
        selected_program=selected_program,
        weight_kg=weight_kg,
        error=error,
        result=result,
    )


@app.route("/programs")
def programs():
    return jsonify(PROGRAMS)


@app.route("/programs/<program_name>")
def program_detail(program_name: str):
    if program_name not in PROGRAMS:
        abort(404, description="Unknown program")
    return jsonify(PROGRAMS[program_name])


@app.route("/estimate-calories", methods=["GET"])
def estimate_calories():
    program = request.args.get("program", type=str)
    weight_kg = request.args.get("weight_kg", type=float)

    if not program or program not in PROGRAMS:
        abort(
            400,
            description="Query param 'program' is required and must be a known program",
        )
    if weight_kg is None or weight_kg <= 0:
        abort(
            400,
            description="Query param 'weight_kg' is required and must be > 0",
        )

    return jsonify(estimate_program_calories(program, weight_kg))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
