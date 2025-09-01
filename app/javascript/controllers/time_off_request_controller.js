import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "list", "errorContainer"];
  static values = {
    indexUrl: String,
    createUrl: String,
    csrfToken: String,
  };

  connect() {
    console.log("Time Off Request controller connected");
    // Set CSRF token value when controller connects
    this.csrfTokenValue = this.getMetaValue("csrf-token");
    // Load time off requests when controller connects
    this.refreshTimeOffRequestsList();
  }

  async submitForm(event) {
    event.preventDefault();

    // Clear any previous errors
    if (this.hasErrorContainerTarget) {
      this.errorContainerTarget.innerHTML = "";
      this.errorContainerTarget.classList.add("d-none");
    }

    const form = event.currentTarget;
    const formData = new FormData(form);
    const url = this.createUrlValue || "/api/v1/time_off_requests";

    try {
      const response = await fetch(url, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.csrfTokenValue,
          Accept: "application/json",
        },
        body: formData,
        credentials: "same-origin", // This ensures cookies (including session) are sent with the request
      });

      const data = await response.json();

      if (!response.ok) {
        // Handle different types of errors
        if (response.status === 401 || response.status === 403) {
          this.handleAuthError();
          return;
        } else {
          this.handleErrors(
            data.errors || ["An error occurred while processing your request."],
          );
        }
        return;
      }

      // On success, update the UI similar to how turbo_stream would
      await this.refreshTimeOffRequestsList();
      this.resetForm();
      this.hideFormAndShowButton();
      this.showNotice("Time off request was successfully created.");
    } catch (error) {
      console.error("Error submitting form:", error);
      this.handleErrors(["An unexpected error occurred. Please try again."]);
    }
  }

  // New reusable function to hide the form and show the button
  hideFormAndShowButton(event) {
    if (event) event.preventDefault(); // Prevent default action if triggered by a button click

    const newRequestFrame = document.getElementById("new_time_off_request");
    if (newRequestFrame) {
      newRequestFrame.innerHTML = `
        <div class="d-grid gap-2 mb-4">
          <a href="/time_off_requests/new" class="btn btn-primary" data-turbo-frame="new_time_off_request">Request Time Off</a>
        </div>
      `;
    }
  }

  // ... (rest of the controller code remains the same) ...
  async refreshTimeOffRequestsList() {
    try {
      const response = await fetch(
        this.indexUrlValue || "/api/v1/time_off_requests",
        {
          headers: {
            Accept: "application/json",
            "X-CSRF-Token": this.csrfTokenValue,
          },
          credentials: "same-origin", // Include cookies with the request
        },
      );

      const data = await response.json();

      if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
          this.handleAuthError();
          return;
        }
        console.error("Error fetching time off requests:", data);
        return;
      }

      // Update the list with the new data
      this.renderTimeOffRequests(data.data);
    } catch (error) {
      console.error("Error refreshing list:", error);
    }
  }

  renderTimeOffRequests(requests) {
    if (!this.hasListTarget) return;

    // Sort requests by created_at in descending order (newest first)
    const sortedRequests = [...requests].sort((a, b) => {
      return (
        new Date(b.attributes.created_at) - new Date(a.attributes.created_at)
      );
    });

    // Generate HTML for each request
    const requestsHtml = sortedRequests
      .map((request) => {
        const attrs = request.attributes;
        const startDate = new Date(attrs.start_date).toLocaleDateString(
          "en-US",
          { month: "short", day: "numeric", year: "numeric" },
        );
        const endDate = new Date(attrs.end_date).toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });

        return `
        <div class="list-group-item d-flex justify-content-between align-items-center">
          <div>
            <strong>${request.id} - ${attrs.time_off_type_name}</strong>
            <div>
              ${startDate} to ${endDate}
            </div>
            <small class="text-muted">${attrs.reason}</small>
          </div>
          <div>
            <span class="badge bg-secondary">${attrs.status.charAt(0).toUpperCase() + attrs.status.slice(1)}</span>
          </div>
        </div>
      `;
      })
      .join("");

    this.listTarget.innerHTML = requestsHtml;
  }

  resetForm() {
    if (this.hasFormTarget) {
      this.formTarget.reset();
    }
  }

  handleErrors(errors) {
    if (!this.hasErrorContainerTarget) return;

    this.errorContainerTarget.classList.remove("d-none");

    const errorList = document.createElement("ul");
    errors.forEach((error) => {
      const li = document.createElement("li");
      li.textContent = error;
      errorList.appendChild(li);
    });

    this.errorContainerTarget.innerHTML = `
      <h2>${errors.length} error(s) prohibited this time off request from being saved:</h2>
    `;
    this.errorContainerTarget.appendChild(errorList);
  }

  showNotice(message, alertClass = "alert-info") {
    const noticeContainer = document.querySelector(".container.mt-4");
    if (!noticeContainer) return;

    const notice = document.createElement("div");
    notice.className = `alert ${alertClass} alert-dismissible fade show`;
    notice.innerHTML = `
      ${message}
      <button class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Insert at the top of the main container
    noticeContainer.insertBefore(notice, noticeContainer.firstChild);

    // Automatically remove after 5 seconds
    setTimeout(() => {
      notice.remove();
    }, 5000);
  }

  getMetaValue(name) {
    const element = document.querySelector(`meta[name="${name}"]`);
    return element && element.getAttribute("content");
  }

  handleAuthError() {
    console.error("Authentication error. You may need to log in again.");

    // Show an error message to the user
    this.showNotice(
      "Your session has expired. Please log in again.",
      "alert-danger",
    );

    // Optionally redirect to login page after a short delay
    setTimeout(() => {
      window.location.href = "/users/sign_in";
    }, 2000);
  }
}
