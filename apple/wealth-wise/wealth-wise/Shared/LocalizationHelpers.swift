import Foundation

/// Localization helper for WealthWise
struct L10n {
    
    // MARK: - App
    struct App {
        static let name = NSLocalizedString("app.name", comment: "App name")
        static let tagline = NSLocalizedString("app.tagline", comment: "App tagline")
        static let welcome = NSLocalizedString("app.welcome", comment: "Welcome message")
    }
    
    // MARK: - Navigation
    struct Nav {
        static let dashboard = NSLocalizedString("nav.dashboard", comment: "Dashboard navigation")
        static let portfolio = NSLocalizedString("nav.portfolio", comment: "Portfolio navigation")
        static let assets = NSLocalizedString("nav.assets", comment: "Assets navigation")
        static let reports = NSLocalizedString("nav.reports", comment: "Reports navigation")
        static let settings = NSLocalizedString("nav.settings", comment: "Settings navigation")
    }
    
    // MARK: - Menu
    struct Menu {
        struct File {
            static let import = NSLocalizedString("menu.file.import", comment: "Import data menu item")
            static let export = NSLocalizedString("menu.file.export", comment: "Export data menu item")
        }
        
        struct View {
            static let dashboard = NSLocalizedString("menu.view.dashboard", comment: "Dashboard view menu")
            static let portfolio = NSLocalizedString("menu.view.portfolio", comment: "Portfolio view menu")
            static let assets = NSLocalizedString("menu.view.assets", comment: "Assets view menu")
            static let reports = NSLocalizedString("menu.view.reports", comment: "Reports view menu")
        }
        
        struct Tools {
            static let security = NSLocalizedString("menu.tools.security", comment: "Security settings menu")
            static let backup = NSLocalizedString("menu.tools.backup", comment: "Backup and restore menu")
        }
    }
    
    // MARK: - Dashboard
    struct Dashboard {
        static let title = NSLocalizedString("dashboard.title", comment: "Dashboard title")
        static let netWorth = NSLocalizedString("dashboard.net_worth", comment: "Total net worth")
        static let portfolioValue = NSLocalizedString("dashboard.portfolio_value", comment: "Portfolio value")
        static let realEstate = NSLocalizedString("dashboard.real_estate", comment: "Real estate value")
        static let cashDeposits = NSLocalizedString("dashboard.cash_deposits", comment: "Cash and deposits")
    }
    
    // MARK: - Sidebar
    struct Sidebar {
        static let overview = NSLocalizedString("sidebar.overview", comment: "Overview section")
        static let assets = NSLocalizedString("sidebar.assets", comment: "Assets section")
        static let allAssets = NSLocalizedString("sidebar.all_assets", comment: "All assets")
        static let stocksETFs = NSLocalizedString("sidebar.stocks_etfs", comment: "Stocks and ETFs")
        static let realEstate = NSLocalizedString("sidebar.real_estate", comment: "Real estate")
        static let commodities = NSLocalizedString("sidebar.commodities", comment: "Commodities")
        static let fixedDeposits = NSLocalizedString("sidebar.fixed_deposits", comment: "Fixed deposits")
        static let cash = NSLocalizedString("sidebar.cash", comment: "Cash")
        static let reports = NSLocalizedString("sidebar.reports", comment: "Reports section")
        static let taxReports = NSLocalizedString("sidebar.tax_reports", comment: "Tax reports")
        static let performance = NSLocalizedString("sidebar.performance", comment: "Performance")
    }
    
    // MARK: - Placeholders
    struct Placeholder {
        static let portfolio = NSLocalizedString("portfolio.description", comment: "Portfolio placeholder")
        static let assets = NSLocalizedString("assets.description", comment: "Assets placeholder")
        static let reports = NSLocalizedString("reports.description", comment: "Reports placeholder")
        static let settings = NSLocalizedString("settings.description", comment: "Settings placeholder")
    }
    
    // MARK: - Currency
    struct Currency {
        static let inr = NSLocalizedString("currency.inr", comment: "Indian Rupee symbol")
        static let usd = NSLocalizedString("currency.usd", comment: "US Dollar symbol")
        static let eur = NSLocalizedString("currency.eur", comment: "Euro symbol")
    }
    
    // MARK: - Actions
    struct Action {
        static let add = NSLocalizedString("action.add", comment: "Add action")
        static let edit = NSLocalizedString("action.edit", comment: "Edit action")
        static let delete = NSLocalizedString("action.delete", comment: "Delete action")
        static let save = NSLocalizedString("action.save", comment: "Save action")
        static let cancel = NSLocalizedString("action.cancel", comment: "Cancel action")
        static let ok = NSLocalizedString("action.ok", comment: "OK action")
    }
    
    // MARK: - Accessibility
    struct Accessibility {
        static let addItem = NSLocalizedString("accessibility.add_item", comment: "Add item accessibility")
        
        static func dashboardCard(_ title: String, _ value: String) -> String {
            return String.localizedStringWithFormat(
                NSLocalizedString("accessibility.dashboard_card", comment: "Dashboard card accessibility"),
                title, value
            )
        }
    }
    
    // MARK: - Errors
    struct Error {
        static let general = NSLocalizedString("error.general", comment: "General error")
        static let dataLoad = NSLocalizedString("error.data_load", comment: "Data load error")
        static let dataSave = NSLocalizedString("error.data_save", comment: "Data save error")
    }
}