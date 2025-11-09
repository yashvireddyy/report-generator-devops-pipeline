import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')  # ✅ Ensures plotting works inside Jenkins/Docker (no display)
import matplotlib.pyplot as plt
import os
import shutil
from datetime import datetime
import zipfile

# === CONFIGURATION ===
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
REPORT_DIR = os.path.join(BASE_DIR, "reports")
STYLE_SRC = os.path.join(BASE_DIR, "style.css")
STYLE_DEST = os.path.join(REPORT_DIR, "style.css")

# Create / Clean reports folder
os.makedirs(REPORT_DIR, exist_ok=True)

# === STEP 1: Generate Mock Data ===
np.random.seed(42)
num_records = 100

data = {
    "Date": pd.date_range(start="2025-01-01", periods=num_records, freq="D"),
    "Region": np.random.choice(["North", "South", "East", "West"], num_records),
    "Product": np.random.choice(["Flooring", "Adhesive", "Coating"], num_records),
    "Units_Sold": np.random.randint(10, 100, num_records),
    "Unit_Price": np.random.uniform(50, 500, num_records).round(2)
}

df = pd.DataFrame(data)
df["Revenue"] = (df["Units_Sold"] * df["Unit_Price"]).round(2)

# === STEP 2: Summary Stats ===
summary = df.groupby("Region")["Revenue"].sum().reset_index()
top_product = (
    df.groupby("Product")["Revenue"].sum()
    .reset_index()
    .sort_values(by="Revenue", ascending=False)
)

# === STEP 3: Visualization ===
plt.figure(figsize=(8, 5))
plt.bar(summary["Region"], summary["Revenue"], color="skyblue")
plt.title("Revenue by Region")
plt.xlabel("Region")
plt.ylabel("Total Revenue")
plt.tight_layout()

chart_path = os.path.join(REPORT_DIR, "revenue_by_region.png")
plt.savefig(chart_path)
plt.close()

# === STEP 4: Copy CSS File ===
if os.path.exists(STYLE_SRC):
    shutil.copy(STYLE_SRC, STYLE_DEST)

# === STEP 5: Save Reports ===
csv_path = os.path.join(REPORT_DIR, "sales_report.csv")
html_path = os.path.join(REPORT_DIR, "sales_report.html")

df.to_csv(csv_path, index=False, encoding='utf-8')

# === STEP 6: Create HTML Report ===
html_content = f"""
<html>
<head>
    <title>Sales Report</title>
    <link rel="stylesheet" type="text/css" href="style.css">
</head>
<body>
    <h1>Automated Sales Report</h1>
    <p><b>Generated on:</b> {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
    <p>This automatically generated report summarizes sales performance by region and product.</p>
    <h2>Data Preview (first 10 rows)</h2>
    {df.head(10).to_html(index=False)}
    <h2>Revenue by Region</h2>
    <img src="revenue_by_region.png" alt="Revenue Chart">
    <h2>Top Products by Revenue</h2>
    {top_product.to_html(index=False)}
</body>
</html>
"""

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_content)

# === STEP 7: Create ZIP Backup ===
zip_path = os.path.join(REPORT_DIR, "reports_backup.zip")
with zipfile.ZipFile(zip_path, 'w') as zipf:
    for root, _, files in os.walk(REPORT_DIR):
        for file in files:
            if not file.endswith(".zip"):
                file_path = os.path.join(root, file)
                zipf.write(file_path, os.path.relpath(file_path, REPORT_DIR))

# === STEP 8: Console Output ===
print("\n✅ Report generation complete!")
print(f"📊 CSV Report: {csv_path}")
print(f"📄 HTML Report: {html_path}")
print(f"🖼️ Chart: {chart_path}")
print(f"🎨 CSS copied to: {STYLE_DEST}")
print(f"🗜️ Zipped backup: {zip_path}")
