from flask import Flask, render_template, request, jsonify
import numpy as np
import tensorflow as tf
import pickle

app = Flask(__name__)

# Load model & scalers
# Suppress eager execution warning if needed, or just load as is
model = tf.keras.models.load_model("lstm_air_quality_model.keras", compile=False)
scaler_X = pickle.load(open("scaler_X.pkl", "rb"))
scaler_y = pickle.load(open("scaler_y.pkl", "rb"))

@app.route("/")
def home():
    return render_template("index.html")

@app.route("/predict", methods=["GET", "POST"])
def predict():
    prediction = None
    error = None

    values = {
        "no2_min": "",
        "no2_max": "",
        "nox_min": "",
        "nox_max": ""
    }

    if request.method == "POST":
        try:
            values["no2_min"] = request.form.get("no2_min", "")
            values["no2_max"] = request.form.get("no2_max", "")
            values["nox_min"] = request.form.get("nox_min", "")
            values["nox_max"] = request.form.get("nox_max", "")

            # Ensure all fields are filled
            if not all(values.values()):
                raise ValueError("All fields are required.")

            no2_min = float(values["no2_min"])
            no2_max = float(values["no2_max"])
            nox_min = float(values["nox_min"])
            nox_max = float(values["nox_max"])

            no2_values = np.linspace(no2_min, no2_max, 24)
            nox_values = np.linspace(nox_min, nox_max, 24)

            X = np.column_stack((no2_values, nox_values))
            X = scaler_X.transform(X)
            X = X.reshape(1, 24, 2)

            y_pred = model.predict(X)
            co_pred = scaler_y.inverse_transform(y_pred)[0][0]

            prediction = round(float(co_pred), 2)

        except Exception as e:
            error = str(e)

    return render_template(
        "predict.html",
        prediction=prediction,
        error=error,
        values=values
    )

@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    message = data.get("message", "").lower()
    
    # Simple predefined responses for the chatbot
    response = "I'm still learning about air quality! Try asking about 'levels' or 'health'."
    
    if "hello" in message or "hi" in message:
        response = "Hello! I can help you understand Air Quality predictions."
    elif "co" in message or "carbon" in message:
        response = "Carbon Monoxide (CO) is a colorless, odorless gas. High levels can be dangerous."
    elif "no2" in message:
        response = "Nitrogen Dioxide (NO2) comes from burning fuel. It can irritate airways and aggravate respiratory diseases."
    elif "nox" in message:
        response = "NOx represents Nitrogen Oxides, a family of poisonous, highly reactive gases including NO2."
    elif "health" in message or "risk" in message:
        response = "Poor air quality can cause breathing issues, headaches, and long-term heart or lung disease."
    elif "source" in message or "cause" in message:
        response = "Main sources include vehicle exhaust, industrial emissions, and power plants."
    elif "prediction" in message:
        response = "Our model uses LSTM neural networks to predict future air quality based on NO2 and NOx levels."
    elif "good" in message or "bad" in message:
        response = "Air quality levels: 0-50 (Good), 51-100 (Moderate), 101-150 (Unhealthy for Sensitive Groups)."

    return jsonify({"response": response})

if __name__ == "__main__":
    app.run(debug=True)
