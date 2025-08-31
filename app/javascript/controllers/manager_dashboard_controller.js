import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "pendingRequests",
    "approvedRequests",
    "rejectedRequests",
    "request",
  ];
  static values = {
    approveUrl: String,
    denyUrl: String,
    timeOffRequestsUrl: String,
  };

  connect() {
    console.log("Manager Dashboard controller connected");
    this.refreshTimeOffRequestsList();
  }

  async approve(event) {
    event.preventDefault();

    const requestId = event.currentTarget.dataset.requestId;
    const url = this.approveUrlValue.replace(":id", requestId);

    this.processDecision(url, requestId, "approved");
  }

  async deny(event) {
    event.preventDefault();

    const requestId = event.currentTarget.dataset.requestId;
    const url = this.denyUrlValue.replace(":id", requestId);

    this.processDecision(url, requestId, "rejected");
  }

  async processDecision(url, requestId, targetListName) {
    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": this.getMetaValue("csrf-token"),
          Accept: "application/json",
          "Content-Type": "application/json",
        },
        credentials: "same-origin",
      });

      let data;
      try {
        data = await response.json();
      } catch (e) {
        console.error("Error parsing JSON response:", e);
        this.showNotice(
          "Error processing response from server",
          "alert-danger",
        );
        return;
      }

      if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
          this.handleAuthError();
          return;
        }
        this.showNotice(
          data.errors ? data.errors[0] : "An error occurred",
          "alert-danger",
        );
        return;
      }

      console.log("Decision processed successfully:", data);

      // Remove the request from the pending list
      const requestElement = document.getElementById(
        `time_off_request_${requestId}`,
      );
      if (requestElement) {
        requestElement.remove();
      }

      // Show success message first
      this.showNotice(
        `Request ${targetListName === "approved" ? "approved" : "denied"} successfully.`,
        "alert-success",
      );

      // Wait a moment before refreshing lists to ensure API consistency
      setTimeout(async () => {
        try {
          // Get the updated list
          await this.refreshLists();
        } catch (refreshError) {
          console.error("Error refreshing lists:", refreshError);
          this.showNotice(
            "Changes were saved but there was an error refreshing the page data.",
            "alert-warning",
          );
        }
      }, 500);
    } catch (error) {
      console.error(
        `Error ${targetListName === "approved" ? "approving" : "denying"} request:`,
        error,
      );
      this.showNotice(
        "An unexpected error occurred. Please try again.",
        "alert-danger",
      );
    }
  }

  async refreshLists() {
    try {
      const response = await fetch(this.timeOffRequestsUrlValue, {
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": this.getMetaValue("csrf-token"),
        },
        credentials: "same-origin",
      });

      const data = await response.json();

      if (!response.ok) {
        if (response.status === 401 || response.status === 403) {
          this.handleAuthError();
          return;
        }
        console.error("Error fetching time off requests:", data);
        return;
      }

      // Update the lists with the new data
      if (data && data.data && Array.isArray(data.data)) {
        console.log("Successfully retrieved requests:", data.data.length);
        this.updateRequestLists(data.data);
      } else {
        console.error("Invalid data format received from API:", data);
        this.showNotice(
          "Error retrieving data. Please refresh the page.",
          "alert-warning",
        );
      }
    } catch (error) {
      console.error("Error refreshing lists:", error);
    }
  }

  updateRequestLists(requests) {
    // Log the received data for debugging
    console.log("Received requests from API:", requests);

    // Group requests by status
    const grouped = { pending: [], approved: [], rejected: [] }; // Initialize with empty arrays for all statuses

    // Process each request and add to the appropriate group
    for (const request of requests) {
      // Make sure attributes exists and has a status property
      if (request && request.attributes && request.attributes.status) {
        const status = request.attributes.status;
        if (grouped[status]) {
          grouped[status].push(request);
        } else {
          console.warn(`Unknown status: ${status}`, request);
        }
      } else {
        console.error("Invalid request object:", request);
      }
    }

    console.log("Grouped requests:", grouped);

    // Update pending requests list
    if (this.hasPendingRequestsTarget) {
      this.updateRequestList(
        this.pendingRequestsTarget,
        grouped.pending || [],
        true,
      );
    }

    // Update approved requests list
    if (this.hasApprovedRequestsTarget) {
      this.updateRequestList(
        this.approvedRequestsTarget,
        grouped.approved || [],
        false,
      );
    }

    // Update rejected requests list
    if (this.hasRejectedRequestsTarget) {
      this.updateRequestList(
        this.rejectedRequestsTarget,
        grouped.rejected || [],
        false,
      );
    }
  }

  updateRequestList(listTarget, requests, showActions) {
    console.log(
      `Updating ${showActions ? "pending" : "processed"} request list with ${requests.length} items`,
    );

    // Sort requests first by user's manager, then by username
    requests.sort((a, b) => {
      const managerA = a.attributes.manager_name || "";
      const managerB = b.attributes.manager_name || "";

      // First sort by manager name
      if (managerA !== managerB) {
        return managerA.localeCompare(managerB);
      }

      // Then by user name
      return a.attributes.user_name.localeCompare(b.attributes.user_name);
    });

    if (requests.length === 0) {
      listTarget.innerHTML = `
        <div class="list-group-item">
          No requests to display.
        </div>
      `;
      return;
    }

    const requestsHtml = requests
      .map((request) => {
        const attrs = request.attributes;
        const startDate = new Date(attrs.start_date).toLocaleDateString(
          "en-US",
          {
            month: "short",
            day: "numeric",
            year: "numeric",
          },
        );
        const endDate = new Date(attrs.end_date).toLocaleDateString("en-US", {
          month: "short",
          day: "numeric",
          year: "numeric",
        });

        let actionsHtml = "";
        if (showActions) {
          actionsHtml = `
          <div class="btn-group">
            <button type="button"
                    data-action="manager-dashboard#approve"
                    data-request-id="${request.id}"
                    class="btn btn-success btn-sm">Approve</button>
            <button type="button"
                    data-action="manager-dashboard#deny"
                    data-request-id="${request.id}"
                    class="btn btn-danger btn-sm">Deny</button>
          </div>
        `;
        }

        return `
        <div id="time_off_request_${request.id}" class="list-group-item d-flex justify-content-between align-items-center">
          <div>
            <strong>${attrs.user_name}</strong>
            ${attrs.manager_name ? `<small class="d-block text-muted">Reports to: ${attrs.manager_name}</small>` : ""}
            <div>${attrs.time_off_type_name}</div>
            <div>${startDate} to ${endDate}</div>
            <small class="text-muted">${attrs.reason}</small>
          </div>
          <div>
            ${actionsHtml}
            <span class="badge bg-secondary">${attrs.status.charAt(0).toUpperCase() + attrs.status.slice(1)}</span>
          </div>
        </div>
      `;
      })
      .join("");

    listTarget.innerHTML = requestsHtml;
  }

  handleAuthError() {
    console.error("Authentication error. You may need to log in again.");

    this.showNotice(
      "Your session has expired. Please log in again.",
      "alert-danger",
    );

    // Redirect to login page after a short delay
    setTimeout(() => {
      window.location.href = "/users/sign_in";
    }, 2000);
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
}
