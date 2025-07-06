# Pagy configuration
require "pagy/extras/bootstrap"

# Set default items per page
Pagy::DEFAULT[:items] = 20

# Enable overflow handling
Pagy::DEFAULT[:overflow] = :last_page
