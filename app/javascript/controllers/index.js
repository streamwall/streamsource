import { application } from "./application"

// Import controllers manually for esbuild
import ModalController from "./modal_controller"
import SearchController from "./search_controller"
import MobileMenuController from "./mobile_menu_controller"
import CollaborativeSpreadsheetController from "./collaborative_spreadsheet_controller"

// Register controllers
application.register("modal", ModalController)
application.register("search", SearchController)
application.register("mobile-menu", MobileMenuController)
application.register("collaborative-spreadsheet", CollaborativeSpreadsheetController)