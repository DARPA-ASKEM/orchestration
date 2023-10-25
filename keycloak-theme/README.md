# TERArium Keycloak Theme
The basis of this CSS was built around the classes/ids of Keycloak's base theme and the overrides from the main Uncharted theme.

If new features are added to the login page there may be some instances where you should make some divs more or less visible.

## Building & Deploying
If any changes are made to the theme the Docker image needs to be rebuild by using the following from the root:
`sh
docker buildx bake
`
>Make sure that you update the version number.

Once build make sure that it is pushed to the appropriate repository.

Finally, update the Kubernetes `keycloak-deployment.yaml` file with the appropriate new version if not using latest and restart the Kubernetes stack.
>The `deploy.sh` script file may need to be updated as well to automatically pull the latest version of the image.

## Theming
Currently **only** the login screen is being rethemed. Additional views can be rethemed as well such as `account`, `admin`, `email` and `welcome` screens. This is a basic approach that can be reused for other screens. If others are made they should be placed as subdirectories under the `xx-theme` directory so that the image generated copies them accordingly.

### Structure
The themes consist of the following root elements. Each `view` you want to theme needs to be in its own folder (such as `login`). Within each view there is a `theme.properties` files that configures the overall theme values. Here you can specify what other theme you are inheriting from, which style file(s) to use and override any Keycloak specific classes to your own. Most of the work including styles, images and scripts are stored as subfolders within the `resources` folder. These would be the `css`, `img` and `js` folders, additionally there is a `messages` folder that can be used for internationalization of text. Files within there must be of the form `messages_xx.properties` where `xx` is the 2 letter country/language code. Note that internationalization must be enabled for the realm you are using.

Finally the main layout and structure of the views is definied within the `FreeMarker` templates with the `.ftl` extensions. This is where one needs to adjust the structure of the view. The base theme templates can be found on [GitHub](https://github.com/keycloak/keycloak/tree/main/themes/src/main/resources/theme) as a reference. Some may need to be pulled and overriden as is currently done with the login, register templates.
