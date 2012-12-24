{Settings}  = GitHub
{MainView}  = GitHub.Views
    
do ->
  try
    appView.addSubView new MainView
      # The Main Namespace
      cssClass: Settings.baseViewClass
  catch error
    notify error