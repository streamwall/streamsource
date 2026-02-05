import { application } from './application'

// Import controllers manually for esbuild
import ModalController from './modal_controller'
import SearchController from './search_controller'
import MobileMenuController from './mobile_menu_controller'
import CollaborativeSpreadsheetController from './collaborative_spreadsheet_controller'
import ReassignDropdownController from './reassign_dropdown_controller'
import StreamerAutocompleteController from './streamer_autocomplete_controller'
import StreamTablePreferencesController from './stream_table_preferences_controller'
import StreamViewController from './stream_view_controller'
import ToastController from './toast_controller'

// Register controllers
application.register('modal', ModalController)
application.register('search', SearchController)
application.register('mobile-menu', MobileMenuController)
application.register('collaborative-spreadsheet', CollaborativeSpreadsheetController)
application.register('reassign-dropdown', ReassignDropdownController)
application.register('streamer-autocomplete', StreamerAutocompleteController)
application.register('stream-table-preferences', StreamTablePreferencesController)
application.register('stream-view', StreamViewController)
application.register('toast', ToastController)
