import streamlit as st
import torch
import torch.nn as nn
import numpy as np
import matplotlib.pyplot as plt
from plot_lib import set_default, plot_data, plot_model, show_scatterplot, plot_bases, show_mat

st.set_page_config(page_title="Deep Learning Visualizer", layout="wide")

st.title("Deep Learning & Math Operations Dashboard")
st.markdown("This dashboard showcases all the graphing functions from `plot_lib.py`.")

# Initialize the global matplotlib style
set_default()

# ---------------------------------------------------------
st.header("1. Data Visualizations (`plot_data` & `show_scatterplot`)")
col1, col2 = st.columns(2)

with col1:
    st.subheader("Scatter Plot (Classes)")
    torch.manual_seed(42)
    X_scatter = torch.randn(300, 2)
    y_scatter = torch.randint(0, 3, (300,))
    
    # plot_data does not clear the figure automatically, so we must manage fig manually
    fig1 = plt.figure()
    plot_data(X_scatter, y_scatter)
    st.pyplot(fig1)
    plt.close(fig1)

with col2:
    st.subheader("Raw Points (`show_scatterplot`)")
    X_raw = torch.randn(200, 2)
    colors = torch.randint(0, 5, (200,))
    
    # show_scatterplot creates its own figure
    show_scatterplot(X_raw, colors, title="Raw Random Points")
    st.pyplot(plt.gcf())
    plt.close()

# ---------------------------------------------------------
st.header("2. Neural Network Decision Boundaries (`plot_model`)")
st.markdown("We create a simple 2-layer Neural Network and visualize how it separates the space.")

# Generate training data
torch.manual_seed(123)
X_train = torch.randn(500, 2)
y_train = torch.randint(0, 2, (500,))

# Create model
model = nn.Sequential(
    nn.Linear(2, 20),
    nn.ReLU(),
    nn.Linear(20, 2)
)

fig3 = plt.figure()
plot_model(X_train, y_train, model)
st.pyplot(fig3)
plt.close(fig3)

# ---------------------------------------------------------
st.header("3. Matrix & Vector Math (`show_mat` & `plot_bases`)")
col3, col4 = st.columns(2)

with col3:
    st.subheader("Matrix Multiplication (`show_mat`)")
    st.markdown("Visualizing `Mat x Vector = Product`")
    mat = torch.randn(10, 10)
    vect = torch.randn(10, 1)
    prod = torch.matmul(mat, vect)
    
    # show_mat creates its own subplots figure
    show_mat(mat, vect, prod)
    st.pyplot(plt.gcf())
    plt.close()

with col4:
    st.subheader("Basis Vectors (`plot_bases`)")
    st.markdown("Shows vectors in a 2D plane as arrows.")
    
    fig4 = plt.figure()
    # plot_bases expects 4 bases vectors: origin_x, origin_y, vector_x, vector_y
    bases = torch.tensor([
        [0.0, 0.0],
        [0.0, 0.0],
        [1.0, 0.0],
        [0.0, 1.0]
    ])
    
    plt.axis('equal')
    plt.axis([-1.5, 1.5, -1.5, 1.5])
    plot_bases(bases)
    st.pyplot(fig4)
    plt.close(fig4)

st.success("All `plot_lib.py` functions rendered successfully!")
