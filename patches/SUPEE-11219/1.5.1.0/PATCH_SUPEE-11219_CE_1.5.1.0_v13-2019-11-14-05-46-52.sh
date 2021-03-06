#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-11219_CE_1510 | CE_1.5.1.0 | v1 | 6d32781149b5c87d245cc1fc0936b19765536362 | Fri Nov 1 20:19:07 2019 +0000 | adcc33c5df92e0985dd5077f0100f17447d0385d..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index 85e4d91cd5d..e8359f36611 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -36,7 +36,27 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
     const XML_PATH_FORGOT_EMAIL_TEMPLATE    = 'admin/emails/forgot_email_template';
     const XML_PATH_FORGOT_EMAIL_IDENTITY    = 'admin/emails/forgot_email_identity';
     const XML_PATH_STARTUP_PAGE             = 'admin/startup/page';
-    const MIN_PASSWORD_LENGTH = 7;
+
+    /**
+     * Minimum length of admin password
+     * @deprecated Use getMinAdminPasswordLength() method instead
+     */
+    const MIN_PASSWORD_LENGTH = 14;
+
+    /**
+     * Configuration path for minimum length of admin password
+     */
+    const XML_PATH_MIN_ADMIN_PASSWORD_LENGTH = 'admin/security/min_admin_password_length';
+
+    /**
+     * Length of salt
+     */
+    const HASH_SALT_LENGTH = 32;
+
+    /**
+     * Empty hash salt
+     */
+    const HASH_SALT_EMPTY = null;
 
     protected $_eventPrefix = 'admin_user';
 
@@ -320,7 +340,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
 
     protected function _getEncodedPassword($pwd)
     {
-        return Mage::helper('core')->getHash($pwd, 2);
+        return Mage::helper('core')->getHashPassword($pwd, self::HASH_SALT_LENGTH);
     }
 
     /**
@@ -419,15 +439,23 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->hasNewPassword()) {
-            if (Mage::helper('core/string')->strlen($this->getNewPassword()) < self::MIN_PASSWORD_LENGTH) {
-                $errors[] = Mage::helper('adminhtml')->__('Password must be at least of %d characters.', self::MIN_PASSWORD_LENGTH);
+            $password = $this->getNewPassword();
+        } elseif ($this->hasPassword()) {
+            $password = $this->getPassword();
+        }
+        if (isset($password)) {
+            $minAdminPasswordLength = $this->getMinAdminPasswordLength();
+            if (Mage::helper('core/string')->strlen($password) < $minAdminPasswordLength) {
+                $errors[] = Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength);
             }
 
-            if (!preg_match('/[a-z]/iu', $this->getNewPassword()) || !preg_match('/[0-9]/u', $this->getNewPassword())) {
-                $errors[] = Mage::helper('adminhtml')->__('Password must include both numeric and alphabetic characters.');
+            if (!preg_match('/[a-z]/iu', $password) || !preg_match('/[0-9]/u', $password)) {
+                $errors[] = Mage::helper('adminhtml')
+                    ->__('Password must include both numeric and alphabetic characters.');
             }
 
-            if ($this->hasPasswordConfirmation() && $this->getNewPassword() != $this->getPasswordConfirmation()) {
+            if ($this->hasPasswordConfirmation() && $password != $this->getPasswordConfirmation()) {
                 $errors[] = Mage::helper('adminhtml')->__('Password confirmation must be same as password.');
             }
 
@@ -495,4 +523,16 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         $emails = str_replace(' ', '', Mage::getStoreConfig(self::XML_PATH_ADDITIONAL_EMAILS));
         return explode(',', $emails);
     }
+
+    /**
+     * Retrieve minimum length of admin password
+     *
+     * @return int
+     */
+    public function getMinAdminPasswordLength()
+    {
+        $minLength = (int)Mage::getStoreConfig(self::XML_PATH_MIN_ADMIN_PASSWORD_LENGTH);
+        $absoluteMinLength = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+        return ($minLength < $absoluteMinLength) ? $absoluteMinLength : $minLength;
+    }
 }
diff --git app/code/core/Mage/Admin/etc/config.xml app/code/core/Mage/Admin/etc/config.xml
index e30c5e7fc26..38ce8f89975 100644
--- app/code/core/Mage/Admin/etc/config.xml
+++ app/code/core/Mage/Admin/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
    <modules>
       <Mage_Admin>
-         <version>0.7.2.1.2</version>
+         <version>0.7.2.1.3</version>
       </Mage_Admin>
    </modules>
 
diff --git app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.2-0.7.2.1.3.php app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.2-0.7.2.1.3.php
new file mode 100644
index 00000000000..5cb89713213
--- /dev/null
+++ app/code/core/Mage/Admin/sql/admin_setup/mysql4-upgrade-0.7.2.1.2-0.7.2.1.3.php
@@ -0,0 +1,39 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Admin
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/** @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+$installer->startSetup();
+
+//Increase password field length
+$installer->getConnection()->changeColumn(
+    $installer->getTable('admin/user'),
+    'password',
+    'password',
+    'VARCHAR(255) NOT NULL DEFAULT \'\' COMMENT \'User Password\''
+);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
index d72b01c94a4..7467a5c0b61 100644
--- app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Api/User/Edit/Tab/Main.php
@@ -88,13 +88,16 @@ class Mage_Adminhtml_Block_Api_User_Edit_Tab_Main extends Mage_Adminhtml_Block_W
             'required' => true,
         ));
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($model->getUserId()) {
             $fieldset->addField('password', 'password', array(
                 'name'  => 'new_api_key',
                 'label' => Mage::helper('adminhtml')->__('New API Key'),
                 'id'    => 'new_pass',
                 'title' => Mage::helper('adminhtml')->__('New API Key'),
-                'class' => 'input-text validate-password',
+                'class' => 'input-text validate-password min-pass-length-' . $minPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('API Key must be at least of %d characters.', $minPasswordLength),
             ));
 
             $fieldset->addField('confirmation', 'password', array(
@@ -105,15 +108,17 @@ class Mage_Adminhtml_Block_Api_User_Edit_Tab_Main extends Mage_Adminhtml_Block_W
             ));
         }
         else {
-           $fieldset->addField('password', 'password', array(
+            $fieldset->addField('password', 'password', array(
                 'name'  => 'api_key',
                 'label' => Mage::helper('adminhtml')->__('API Key'),
                 'id'    => 'customer_pass',
                 'title' => Mage::helper('adminhtml')->__('API Key'),
-                'class' => 'input-text required-entry validate-password',
+                'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                 'required' => true,
+                'note' => Mage::helper('adminhtml')
+                    ->__('API Key must be at least of %d characters.', $minPasswordLength),
             ));
-           $fieldset->addField('confirmation', 'password', array(
+            $fieldset->addField('confirmation', 'password', array(
                 'name'  => 'api_key_confirmation',
                 'label' => Mage::helper('adminhtml')->__('API Key Confirmation'),
                 'id'    => 'confirmation',
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
index ec8bcfb2847..ddd385c453b 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Attribute/Set/Main.php
@@ -93,10 +93,13 @@ class Mage_Adminhtml_Block_Catalog_Product_Attribute_Set_Main extends Mage_Admin
                 'class'     => 'save'
         )));
 
+        $deleteConfirmMessage = $this->jsQuoteEscape(Mage::helper('catalog')
+            ->__('All products of this set will be deleted! Are you sure you want to delete this attribute set?'));
+        $deleteUrl = $this->getUrlSecure('*/*/delete', array('id' => $setId));
         $this->setChild('delete_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->setData(array(
                 'label'     => Mage::helper('catalog')->__('Delete Attribute Set'),
-                'onclick'   => 'deleteConfirm(\''. $this->jsQuoteEscape(Mage::helper('catalog')->__('All products of this set will be deleted! Are you sure you want to delete this attribute set?')) . '\', \'' . $this->getUrl('*/*/delete', array('id' => $setId)) . '\')',
+                'onclick'   => 'deleteConfirm(\'' . $deleteConfirmMessage . '\', \'' . $deleteUrl . '\')',
                 'class'     => 'delete'
         )));
 
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
index 61e5ce3061c..9f3446badc4 100644
--- app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
+++ app/code/core/Mage/Adminhtml/Block/Customer/Edit/Renderer/Newpass.php
@@ -38,7 +38,11 @@ class Mage_Adminhtml_Block_Customer_Edit_Renderer_Newpass extends Mage_Adminhtml
     {
         $html = '<tr>';
         $html.= '<td class="label">'.$element->getLabelHtml().'</td>';
-        $html.= '<td class="value">'.$element->getElementHtml().'</td>';
+        $html .= '<td class="value">' . $element->getElementHtml();
+        if ($element->getNote()) {
+            $html .= '<p class="note"><span>' . $element->getNote() . '</span></p>';
+        }
+        $html .= '</td>';
         $html.= '</tr>'."\n";
         $html.= '<tr>';
         $html.= '<td class="label"><label>&nbsp;</label></td>';
diff --git app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
index c1e7d31a5e0..9920f403550 100644
--- app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
+++ app/code/core/Mage/Adminhtml/Block/Customer/Edit/Tab/Account.php
@@ -63,8 +63,12 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
         $this->_setFieldset($attributes, $fieldset);
 
         if ($customer->getId()) {
-            $form->getElement('website_id')->setDisabled('disabled');
-            $form->getElement('created_in')->setDisabled('disabled');
+            if ($element = $form->getElement('website_id')) {
+                $element->setDisabled('disabled');
+            }
+            if ($element = $form->getElement('created_in')) {
+                $element->setDisabled('disabled');
+            }
         } else {
             $fieldset->removeField('created_in');
         }
@@ -117,6 +121,7 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
             }
         }
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($customer->getId()) {
             if (!$customer->isReadonly()) {
                 // add password management fieldset
@@ -129,7 +134,9 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
                     array(
                         'label' => Mage::helper('customer')->__('New Password'),
                         'name'  => 'new_password',
-                        'class' => 'validate-new-password'
+                        'class' => 'validate-new-password min-pass-length-' . $minPasswordLength,
+                        'note' => Mage::helper('adminhtml')
+                            ->__('Password must be at least of %d characters.', $minPasswordLength),
                     )
                 );
                 $field->setRenderer($this->getLayout()->createBlock('adminhtml/customer_edit_renderer_newpass'));
@@ -166,9 +173,11 @@ class Mage_Adminhtml_Block_Customer_Edit_Tab_Account extends Mage_Adminhtml_Bloc
             $field = $newFieldset->addField('password', 'text',
                 array(
                     'label' => Mage::helper('customer')->__('Password'),
-                    'class' => 'input-text required-entry validate-password',
+                    'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                     'name'  => 'password',
-                    'required' => true
+                    'required' => true,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
             $field->setRenderer($this->getLayout()->createBlock('adminhtml/customer_edit_renderer_newpass'));
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index eee0ac7360b..0bfac2c3a0c 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -76,6 +76,9 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
             $templateProcessed = "<pre>" . htmlspecialchars($templateProcessed) . "</pre>";
         }
 
+        $templateProcessed = Mage::getSingleton('core/input_filter_maliciousCode')
+            ->linkFilter($templateProcessed);
+
         Varien_Profiler::stop("newsletter_queue_proccessing");
 
         return $templateProcessed;
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
index a35860df692..01931b32b73 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Edit.php
@@ -315,7 +315,7 @@ class Mage_Adminhtml_Block_Newsletter_Template_Edit extends Mage_Adminhtml_Block
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array('id' => $this->getRequest()->getParam('id')));
+        return $this->getUrlSecure('*/*/delete', array('id' => $this->getRequest()->getParam('id')));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index 55031b2b53e..6f8deca70bd 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -74,6 +74,9 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $templateProcessed = "<pre>" . htmlspecialchars($templateProcessed) . "</pre>";
         }
 
+        $templateProcessed = Mage::getSingleton('core/input_filter_maliciousCode')
+            ->linkFilter($templateProcessed);
+
         Varien_Profiler::stop("newsletter_template_proccessing");
 
         return $templateProcessed;
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
index 5ea476a8028..7a1e33cf380 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Tab/Useredit.php
@@ -85,6 +85,7 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
             )
         );
 
+        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
         if ($user->getUserId()) {
             $fieldset->addField('password', 'password',
                 array(
@@ -92,7 +93,9 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
                     'label' => Mage::helper('adminhtml')->__('New Password'),
                     'id'    => 'new_pass',
                     'title' => Mage::helper('adminhtml')->__('New Password'),
-                    'class' => 'input-text validate-password',
+                    'class' => 'input-text validate-password min-pass-length-' . $minPasswordLength,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
 
@@ -112,8 +115,10 @@ class Mage_Adminhtml_Block_Permissions_Tab_Useredit extends Mage_Adminhtml_Block
                     'label' => Mage::helper('adminhtml')->__('Password'),
                     'id'    => 'customer_pass',
                     'title' => Mage::helper('adminhtml')->__('Password'),
-                    'class' => 'input-text required-entry validate-password',
+                    'class' => 'input-text required-entry validate-password min-pass-length-' . $minPasswordLength,
                     'required' => true,
+                    'note' => Mage::helper('adminhtml')
+                        ->__('Password must be at least of %d characters.', $minPasswordLength),
                 )
             );
            $fieldset->addField('confirmation', 'password',
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
index 2887bc0d1ba..7a9c7020f0f 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/User/Edit/Tab/Main.php
@@ -88,13 +88,16 @@ class Mage_Adminhtml_Block_Permissions_User_Edit_Tab_Main extends Mage_Adminhtml
             'required' => true,
         ));
 
+        $minAdminPasswordLength = Mage::getModel('admin/user')->getMinAdminPasswordLength();
         if ($model->getUserId()) {
             $fieldset->addField('password', 'password', array(
                 'name'  => 'new_password',
                 'label' => Mage::helper('adminhtml')->__('New Password'),
                 'id'    => 'new_pass',
                 'title' => Mage::helper('adminhtml')->__('New Password'),
-                'class' => 'input-text validate-admin-password',
+                'class' => 'input-text validate-admin-password min-admin-pass-length-' . $minAdminPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             ));
 
             $fieldset->addField('confirmation', 'password', array(
@@ -105,15 +108,18 @@ class Mage_Adminhtml_Block_Permissions_User_Edit_Tab_Main extends Mage_Adminhtml
             ));
         }
         else {
-           $fieldset->addField('password', 'password', array(
+            $fieldset->addField('password', 'password', array(
                 'name'  => 'password',
                 'label' => Mage::helper('adminhtml')->__('Password'),
                 'id'    => 'customer_pass',
                 'title' => Mage::helper('adminhtml')->__('Password'),
-                'class' => 'input-text required-entry validate-admin-password',
+                'class' => 'input-text required-entry validate-admin-password min-admin-pass-length-'
+                    . $minAdminPasswordLength,
                 'required' => true,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             ));
-           $fieldset->addField('confirmation', 'password', array(
+            $fieldset->addField('confirmation', 'password', array(
                 'name'  => 'password_confirmation',
                 'label' => Mage::helper('adminhtml')->__('Password Confirmation'),
                 'id'    => 'confirmation',
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index 5ee8f9da4af..82e2ca8d529 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -218,7 +218,7 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
 
     public function getCancelUrl()
     {
-        return $this->getUrl('*/*/cancel');
+        return $this->getUrlSecure('*/*/cancel');
     }
 
     public function getInvoiceUrl()
diff --git app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
index 1166aac899b..a93def3abdd 100644
--- app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
+++ app/code/core/Mage/Adminhtml/Block/System/Account/Edit/Form.php
@@ -82,11 +82,14 @@ class Mage_Adminhtml_Block_System_Account_Edit_Form extends Mage_Adminhtml_Block
             )
         );
 
+        $minAdminPasswordLength = Mage::getModel('admin/user')->getMinAdminPasswordLength();
         $fieldset->addField('password', 'password', array(
                 'name'  => 'new_password',
                 'label' => Mage::helper('adminhtml')->__('New Password'),
                 'title' => Mage::helper('adminhtml')->__('New Password'),
-                'class' => 'input-text validate-admin-password',
+                'class' => 'input-text validate-admin-password min-admin-pass-length-' . $minAdminPasswordLength,
+                'note' => Mage::helper('adminhtml')
+                    ->__('Password must be at least of %d characters.', $minAdminPasswordLength),
             )
         );
 
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
index 77c8a12cd5b..447c32b2d45 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Edit.php
@@ -267,7 +267,7 @@ class Mage_Adminhtml_Block_System_Email_Template_Edit extends Mage_Adminhtml_Blo
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl('*/*/delete', array('_current' => true));
+        return $this->getUrlSecure('*/*/delete', array('_current' => true));
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid.php app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
index 6411ca25fa5..819f3ed3755 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid.php
@@ -437,7 +437,7 @@ class Mage_Adminhtml_Block_Widget_Grid extends Mage_Adminhtml_Block_Widget
     {
         if ($this->getCollection()) {
             $field = ( $column->getFilterIndex() ) ? $column->getFilterIndex() : $column->getIndex();
-            if ($column->getFilterConditionCallback()) {
+            if ($column->getFilterConditionCallback() && $column->getFilterConditionCallback()[0] instanceof self) {
                 call_user_func($column->getFilterConditionCallback(), $this->getCollection(), $column);
             } else {
                 $cond = $column->getFilter()->getCondition();
diff --git app/code/core/Mage/Adminhtml/Model/Config/Data.php app/code/core/Mage/Adminhtml/Model/Config/Data.php
index 1250741b4e0..0965c530160 100644
--- app/code/core/Mage/Adminhtml/Model/Config/Data.php
+++ app/code/core/Mage/Adminhtml/Model/Config/Data.php
@@ -34,6 +34,10 @@
 
 class Mage_Adminhtml_Model_Config_Data extends Varien_Object
 {
+    const SCOPE_DEFAULT  = 'default';
+    const SCOPE_WEBSITES = 'websites';
+    const SCOPE_STORES   = 'stores';
+
     /**
      * Save config section
      * Require set: section, website, store and groups
@@ -250,13 +254,13 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
     protected function _getScope()
     {
         if ($this->getStore()) {
-            $scope   = 'stores';
+            $scope   = self::SCOPE_STORES;
             $scopeId = (int)Mage::getConfig()->getNode('stores/' . $this->getStore() . '/system/store/id');
         } elseif ($this->getWebsite()) {
-            $scope   = 'websites';
+            $scope   = self::SCOPE_WEBSITES;
             $scopeId = (int)Mage::getConfig()->getNode('websites/' . $this->getWebsite() . '/system/website/id');
         } else {
-            $scope   = 'default';
+            $scope   = self::SCOPE_DEFAULT;
             $scopeId = 0;
         }
         $this->setScope($scope);
@@ -302,4 +306,100 @@ class Mage_Adminhtml_Model_Config_Data extends Varien_Object
         }
         return $config;
     }
+
+    /**
+     * Secure set groups
+     *
+     * @param array $groups
+     * @return Mage_Adminhtml_Model_Config_Data
+     * @throws Mage_Core_Exception
+     */
+    public function setGroupsSecure($groups)
+    {
+        $this->_validate();
+        $this->_getScope();
+
+        $groupsSecure = array();
+        $section = $this->getSection();
+        $sections = Mage::getModel('adminhtml/config')->getSections();
+
+        foreach ($groups as $group => $groupData) {
+            $groupConfig = $sections->descend($section . '/groups/' . $group);
+            foreach ($groupData['fields'] as $field => $fieldData) {
+                $fieldName = $field;
+                if ($groupConfig && $groupConfig->clone_fields) {
+                    if ($groupConfig->clone_model) {
+                        $cloneModel = Mage::getModel((string)$groupConfig->clone_model);
+                    } else {
+                        Mage::throwException(
+                            $this->__('Config form fieldset clone model required to be able to clone fields')
+                        );
+                    }
+                    foreach ($cloneModel->getPrefixes() as $prefix) {
+                        if (strpos($field, $prefix['field']) === 0) {
+                            $field = substr($field, strlen($prefix['field']));
+                        }
+                    }
+                }
+                $fieldConfig = $sections->descend($section . '/groups/' . $group . '/fields/' . $field);
+                if (!$fieldConfig) {
+                    $node = $sections->xpath($section . '//' . $group . '[@type="group"]/fields/' . $field);
+                    if ($node) {
+                        $fieldConfig = $node[0];
+                    }
+                }
+                if (($groupConfig ? !$groupConfig->dynamic_group : true) && !$this->_isValidField($fieldConfig)) {
+                    Mage::throwException(Mage::helper('adminhtml')->__('Wrong field specified.'));
+                }
+                $groupsSecure[$group]['fields'][$fieldName] = $fieldData;
+            }
+        }
+
+        $this->setGroups($groupsSecure);
+
+        return $this;
+    }
+
+    /**
+     * Check field visibility by scope
+     *
+     * @param Mage_Core_Model_Config_Element $field
+     * @return bool
+     */
+    protected function _isValidField($field)
+    {
+        if (!$field) {
+            return false;
+        }
+
+        switch ($this->getScope()) {
+            case self::SCOPE_DEFAULT:
+                return (bool)(int)$field->show_in_default;
+                break;
+            case self::SCOPE_WEBSITES:
+                return (bool)(int)$field->show_in_website;
+                break;
+            case self::SCOPE_STORES:
+                return (bool)(int)$field->show_in_store;
+                break;
+        }
+
+        return true;
+    }
+
+    /**
+     * Select group setter is secure or not based on the configuration
+     *
+     * @param array $groups
+     * @return Mage_Adminhtml_Model_Config_Data
+     * @throws Mage_Core_Exception
+     */
+    public function setGroupsSelector($groups)
+    {
+        if (Mage::getStoreConfigFlag('admin/security/secure_system_configuration_save_disabled')) {
+            return $this->setGroups($groups);
+        }
+
+        return $this->setGroupsSecure($groups);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 6bf14f4d96d..0e644ac4aab 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -53,33 +53,26 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @var array
      */
-    protected $_disallowedXPathExpressions = array(
-        '*//template',
-        '*//@template',
-        '//*[@method=\'setTemplate\']',
-        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
-        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
-    );
+    protected $_disallowedXPathExpressions = array();
 
     /**
      * Disallowed template name
      *
      * @var array
      */
-    protected $_disallowedBlock = array(
-        'Mage_Install_Block_End',
-        'Mage_Rss_Block_Order_New',
-        'Mage_Core_Block_Template_Zend',
-    );
+    protected $_disallowedBlock = array();
+
+    /**
+     * @var Mage_Core_Model_Layout_Validator
+     */
+    protected $_validator;
 
     /**
      * Protected expressions
      *
      * @var array
      */
-    protected $_protectedExpressions = array(
-        self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR => '//action/*[@helper]',
-    );
+    protected $_protectedExpressions = array();
 
     /**
      * Construct
@@ -87,27 +80,17 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     public function __construct()
     {
         $this->_initMessageTemplates();
+        $this->_initValidator();
     }
 
     /**
-     * Initialize messages templates with translating
+     * Returns array of validation failure messages
      *
-     * @return Mage_Adminhtml_Model_LayoutUpdate_Validator
+     * @return array
      */
-    protected function _initMessageTemplates()
+    public function getMessages()
     {
-        if (!$this->_messageTemplates) {
-            $this->_messageTemplates = array(
-                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
-                    Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
-                self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
-                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
-                    'Invalid template path used in layout update.'
-                ),
-                self::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
-            );
-        }
-        return $this;
+        return $this->_validator->getMessages();
     }
 
     /**
@@ -124,43 +107,42 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     public function isValid($value)
     {
-        if (is_string($value)) {
-            $value = trim($value);
-            try {
-                //wrap XML value in the "config" tag because config cannot
-                //contain multiple root tags
-                $value = new Varien_Simplexml_Element('<config>' . $value . '</config>');
-            } catch (Exception $e) {
-                $this->_error(self::XML_INVALID);
-                return false;
-            }
-        } elseif (!($value instanceof Varien_Simplexml_Element)) {
-            throw new Exception(
-                Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'));
-        }
+        return $this->_validator->isValid($value);
+    }
 
-        if ($value->xpath($this->_getXpathBlockValidationExpression())) {
-            $this->_error(self::INVALID_BLOCK_NAME);
-            return false;
-        }
-        // if layout update declare custom templates then validate their paths
-        if ($templatePaths = $value->xpath($this->_getXpathValidationExpression())) {
-            try {
-                $this->_validateTemplatePath($templatePaths);
-            } catch (Exception $e) {
-                $this->_error(self::INVALID_TEMPLATE_PATH);
-                return false;
-            }
-        }
-        $this->_setValue($value);
+    /**
+     * Initialize the validator instance with populated template messages
+     */
+    protected function _initValidator()
+    {
+        $this->_validator = Mage::getModel('core/layout_validator');
+        $this->_disallowedBlock = $this->_validator->getDisallowedBlocks();
+        $this->_protectedExpressions = $this->_validator->getProtectedExpressions();
+        $this->_disallowedXPathExpressions = $this->_validator->getDisallowedXpathValidationExpression();
+        $this->_validator->setMessages($this->_messageTemplates);
+    }
 
-        foreach ($this->_protectedExpressions as $key => $xpr) {
-            if ($this->_value->xpath($xpr)) {
-                $this->_error($key);
-                return false;
-            }
+    /**
+     * Initialize messages templates with translating
+     *
+     * @return Mage_Adminhtml_Model_LayoutUpdate_Validator
+     */
+    protected function _initMessageTemplates()
+    {
+        if (!$this->_messageTemplates) {
+            $this->_messageTemplates = array(
+                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
+                    Mage::helper('adminhtml')->__('Helper attributes should not be used in custom layout updates.'),
+                self::XML_INVALID => Mage::helper('adminhtml')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('adminhtml')->__(
+                    'Invalid template path used in layout update.'
+                ),
+                Mage_Core_Model_Layout_Validator::INVALID_BLOCK_NAME => Mage::helper('adminhtml')->__('Disallowed block name for frontend.'),
+                Mage_Core_Model_Layout_Validator::INVALID_XML_OBJECT_EXCEPTION =>
+                    Mage::helper('adminhtml')->__('XML object is not instance of "Varien_Simplexml_Element".'),
+            );
         }
-        return true;
+        return $this;
     }
 
     /**
@@ -168,8 +150,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @return string xPath for validate incorrect path to template
      */
-    protected function _getXpathValidationExpression() {
-        return implode(" | ", $this->_disallowedXPathExpressions);
+    protected function _getXpathValidationExpression()
+    {
+        return $this->_validator->getXpathValidationExpression();
     }
 
     /**
@@ -177,16 +160,9 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      *
      * @return string xPath for validate incorrect block name
      */
-    protected function _getXpathBlockValidationExpression() {
-        $xpath = "";
-        if (count($this->_disallowedBlock)) {
-            foreach ($this->_disallowedBlock as $key => $value) {
-                $xpath .= $key > 0 ? " | " : '';
-                $xpath .= "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
-                $xpath .= "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
-            }
-        }
-        return $xpath;
+    protected function _getXpathBlockValidationExpression()
+    {
+        return $this->_validator->getXpathBlockValidationExpression();
     }
 
     /**
@@ -197,14 +173,6 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
      */
     protected function _validateTemplatePath(array $templatePaths)
     {
-        /**@var $path Varien_Simplexml_Element */
-        foreach ($templatePaths as $path) {
-            if ($path->hasChildren()) {
-                $path = stripcslashes(trim((string) $path->children(), '"'));
-            }
-            if (strpos($path, '..' . DS) !== false) {
-                throw new Exception();
-            }
-        }
+        $this->_validator->validateTemplatePath($templatePaths);
     }
 }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index 63c995411d5..a0fe4576205 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -45,6 +45,39 @@ class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_
         $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
             ->toOptionArray(true);
 
+        if (!function_exists('array_column')) {
+            function array_column(array $allCurrenciesOptions, $columnKey, $indexKey = null)
+            {
+                $array = array();
+                foreach ($allCurrenciesOptions as $allCurrenciesOption) {
+                    if (!array_key_exists($columnKey, $allCurrenciesOption)) {
+                        Mage::getSingleton('adminhtml/session')->addError(
+                            Mage::helper('adminhtml')->__("Key %s does not exist in array", $columnKey)
+                        );
+                        return false;
+                    }
+                    if (is_null($indexKey)) {
+                        $array[] = $allCurrenciesOption[$columnKey];
+                    } else {
+                        if (!array_key_exists($indexKey, $allCurrenciesOption)) {
+                            Mage::getSingleton('adminhtml/session')->addError(
+                                Mage::helper('adminhtml')->__("Key %s does not exist in array", $indexKey)
+                            );
+                            return false;
+                        }
+                        if (!is_scalar($allCurrenciesOption[$indexKey])) {
+                            Mage::getSingleton('adminhtml/session')->addError(
+                                Mage::helper('adminhtml')->__("Key %s does not contain scalar value", $indexKey)
+                            );
+                            return false;
+                        }
+                        $array[$allCurrenciesOption[$indexKey]] = $allCurrenciesOption[$columnKey];
+                    }
+                }
+                return $array;
+            }
+        }
+
         $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
 
         foreach ($this->getValue() as $currency) {
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php
new file mode 100644
index 00000000000..a2793373a80
--- /dev/null
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Passwordlength.php
@@ -0,0 +1,50 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Password length config field backend model
+ *
+ * @category    Mage
+ * @package     Mage_Adminhtml
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Adminhtml_Model_System_Config_Backend_Passwordlength extends  Mage_Core_Model_Config_Data
+{
+    /**
+     * Before save processing
+     *
+     * @throws Mage_Core_Exception
+     * @return Mage_Adminhtml_Model_System_Config_Backend_Passwordlength
+     */
+    protected function _beforeSave()
+    {
+        if ((int)$this->getValue() < Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH) {
+            Mage::throwException(Mage::helper('adminhtml')
+                ->__('Password must be at least of %d characters.', Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH));
+        }
+        return $this;
+    }
+}
diff --git app/code/core/Mage/Adminhtml/controllers/Api/UserController.php app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
index 4dfe7bc7026..279e8b27323 100644
--- app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
+++ app/code/core/Mage/Adminhtml/controllers/Api/UserController.php
@@ -111,6 +111,31 @@ class Mage_Adminhtml_Api_UserController extends Mage_Adminhtml_Controller_Action
                 return;
             }
             $model->setData($data);
+
+            if ($model->hasNewApiKey() && $model->getNewApiKey() === '') {
+                $model->unsNewApiKey();
+            }
+
+            if ($model->hasApiKeyConfirmation() && $model->getApiKeyConfirmation() === '') {
+                $model->unsApiKeyConfirmation();
+            }
+
+            $result = $model->validate();
+
+            if (is_array($result)) {
+                foreach ($result as $error) {
+                    $this->_getSession()->addError($error);
+                }
+                if ($id) {
+                    $this->_getSession()->setUserData($data);
+                    $this->_redirect('*/*/edit', array('user_id' => $id));
+                } else {
+                    $this->_getSession()->setUserData($data);
+                    $this->_redirect('*/*/new');
+                }
+                return;
+            }
+
             try {
                 $model->save();
                 if ( $uRoles = $this->getRequest()->getParam('roles', false) ) {
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
index f734fa7e8bd..af74026202b 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/CategoryController.php
@@ -481,4 +481,15 @@ class Mage_Adminhtml_Catalog_CategoryController extends Mage_Adminhtml_Controlle
     {
         return Mage::getSingleton('admin/session')->isAllowed('catalog/categories');
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
index b374b44ef4e..62e3b4bf60e 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
@@ -244,6 +244,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
                     return;
                 }
 
+                $data['backend_model'] = $model->getBackendModel();
                 $data['attribute_code'] = $model->getAttributeCode();
                 $data['is_user_defined'] = $model->getIsUserDefined();
                 $data['frontend_input'] = $model->getFrontendInput();
@@ -334,7 +335,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
 
             // entity type check
             $model->load($id);
-            if ($model->getEntityTypeId() != $this->_entityTypeId) {
+            if ($model->getEntityTypeId() != $this->_entityTypeId || !$model->getIsUserDefined()) {
                 Mage::getSingleton('adminhtml/session')->addError(
                     Mage::helper('catalog')->__('This attribute cannot be deleted.'));
                 $this->_redirect('*/*/');
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
index 970620540ba..97b443a494d 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/SetController.php
@@ -208,6 +208,17 @@ class Mage_Adminhtml_Catalog_Product_SetController extends Mage_Adminhtml_Contro
         }
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Define in register catalog_product entity type code as entityType
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
index c8d97a3891c..59c5242a6e9 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/SearchController.php
@@ -190,6 +190,17 @@ class Mage_Adminhtml_Catalog_SearchController extends Mage_Adminhtml_Controller_
         $this->_redirect('*/*/index');
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete', 'massDelete');
+        return parent::preDispatch();
+    }
+
     protected function _isAllowed()
     {
         return Mage::getSingleton('admin/session')->isAllowed('catalog/search');
diff --git app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
index efa6e3118e2..bf87e6142d7 100644
--- app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
+++ app/code/core/Mage/Adminhtml/controllers/Cms/PageController.php
@@ -215,6 +215,17 @@ class Mage_Adminhtml_Cms_PageController extends Mage_Adminhtml_Controller_Action
         $this->_redirect('*/*/');
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check the permission to run it
      *
diff --git app/code/core/Mage/Adminhtml/controllers/CustomerController.php app/code/core/Mage/Adminhtml/controllers/CustomerController.php
index c371c607047..dbf9209e602 100644
--- app/code/core/Mage/Adminhtml/controllers/CustomerController.php
+++ app/code/core/Mage/Adminhtml/controllers/CustomerController.php
@@ -329,9 +329,15 @@ class Mage_Adminhtml_CustomerController extends Mage_Adminhtml_Controller_Action
                 }
 
                 if (!empty($data['account']['new_password'])) {
-                    $newPassword = $data['account']['new_password'];
+                    $newPassword = trim($data['account']['new_password']);
                     if ($newPassword == 'auto') {
                         $newPassword = $customer->generatePassword();
+                    } else {
+                        $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+                        if (Mage::helper('core/string')->strlen($newPassword) < $minPasswordLength) {
+                            Mage::throwException(Mage::helper('customer')
+                                ->__('The minimum password length is %s', $minPasswordLength));
+                        }
                     }
                     $customer->changePassword($newPassword);
                     $customer->sendPasswordReminderEmail();
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index e6a86f92250..1859600681a 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -249,4 +249,15 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         $this->getLayout()->getBlock('preview_form')->setFormData($data);
         $this->renderLayout();
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
index eb91f850de1..97b81ea03ec 100644
--- app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
+++ app/code/core/Mage/Adminhtml/controllers/Permissions/BlockController.php
@@ -204,6 +204,17 @@ class Mage_Adminhtml_Permissions_BlockController extends Mage_Adminhtml_Controll
             );
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check permissions before allow edit list of blocks
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
index 2047ead154a..d0de0d2e906 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/OrderController.php
@@ -751,4 +751,15 @@ class Mage_Adminhtml_Sales_OrderController extends Mage_Adminhtml_Controller_Act
             $this->_redirect('*/*/');
         }
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('cancel', 'massCancel');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
index 6f701ea7c9b..c8a7ded516c 100644
--- app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/ConfigController.php
@@ -149,7 +149,7 @@ class Mage_Adminhtml_System_ConfigController extends Mage_Adminhtml_Controller_A
                 ->setSection($section)
                 ->setWebsite($website)
                 ->setStore($store)
-                ->setGroups($groups)
+                ->setGroupsSelector($groups)
                 ->save();
 
             // reinit configuration
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index 299bb73bdfa..b032396c9c7 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -107,7 +107,7 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
-            $allowedHtmlTags = ['template_text', 'styles'];
+            $allowedHtmlTags = ['template_text', 'styles', 'variables'];
             if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
                 Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
             }
@@ -204,6 +204,17 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($template->getData()));
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Load email template from request
      *
diff --git app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
index 17460b25ba2..b4fe8052b95 100644
--- app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
+++ app/code/core/Mage/Adminhtml/controllers/Tax/RuleController.php
@@ -170,4 +170,15 @@ class Mage_Adminhtml_Tax_RuleController extends Mage_Adminhtml_Controller_Action
     {
         return Mage::getSingleton('admin/session')->isAllowed('sales/tax/rules');
     }
+
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
 }
diff --git app/code/core/Mage/Api/Model/User.php app/code/core/Mage/Api/Model/User.php
index 885bdf05ef6..f4cded6fd84 100644
--- app/code/core/Mage/Api/Model/User.php
+++ app/code/core/Mage/Api/Model/User.php
@@ -211,7 +211,78 @@ class Mage_Api_Model_User extends Mage_Core_Model_Abstract
 
     protected function _getEncodedApiKey($apiKey)
     {
-        return Mage::helper('core')->getHash($apiKey, 2);
+        return Mage::helper('core')->getHashPassword($apiKey, Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
+
+    /**
+     * Validate user attribute values.
+     *
+     * @return array|bool
+     * @throws Zend_Validate_Exception
+     */
+    public function validate()
+    {
+        $errors = new ArrayObject();
+
+        if (!Zend_Validate::is($this->getUsername(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('User Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getFirstname(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('First Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getLastname(), 'NotEmpty')) {
+            $errors[] = Mage::helper('api')->__('Last Name is required field.');
+        }
+
+        if (!Zend_Validate::is($this->getEmail(), 'EmailAddress')) {
+            $errors[] = Mage::helper('api')->__('Please enter a valid email.');
+        }
+
+        if ($this->hasNewApiKey()) {
+            $apiKey = $this->getNewApiKey();
+        } elseif ($this->hasApiKey()) {
+            $apiKey = $this->getApiKey();
+        }
+
+        if (isset($apiKey)) {
+            $minCustomerPasswordLength = $this->_getMinCustomerPasswordLength();
+            if (strlen($apiKey) < $minCustomerPasswordLength) {
+                $errors[] = Mage::helper('api')
+                    ->__('Api Key must be at least of %d characters.', $minCustomerPasswordLength);
+            }
+
+            if (!preg_match('/[a-z]/iu', $apiKey) || !preg_match('/[0-9]/u', $apiKey)) {
+                $errors[] = Mage::helper('api')
+                    ->__('Api Key must include both numeric and alphabetic characters.');
+            }
+
+            if ($this->hasApiKeyConfirmation() && $apiKey != $this->getApiKeyConfirmation()) {
+                $errors[] = Mage::helper('api')->__('Api Key confirmation must be same as Api Key.');
+            }
+        }
+
+        if ($this->userExists()) {
+            $errors[] = Mage::helper('api')
+                ->__('A user with the same user name or email already exists.');
+        }
+
+        if (count($errors) === 0) {
+            return true;
+        }
+
+        return (array) $errors;
+    }
+
+    /**
+     * Get min customer password length
+     *
+     * @return int
+     */
+    protected function _getMinCustomerPasswordLength()
+    {
+        return Mage::getSingleton('customer/customer')->getMinPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Api/etc/config.xml app/code/core/Mage/Api/etc/config.xml
index 63121dee3ad..3fa4a6f35e0 100644
--- app/code/core/Mage/Api/etc/config.xml
+++ app/code/core/Mage/Api/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Api>
-            <version>0.8.1</version>
+            <version>0.8.1.1.2</version>
         </Mage_Api>
     </modules>
     <global>
diff --git app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-0.8.1.1.1-0.8.1.1.2.php app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-0.8.1.1.1-0.8.1.1.2.php
new file mode 100644
index 00000000000..2722c2ea245
--- /dev/null
+++ app/code/core/Mage/Api/sql/api_setup/mysql4-upgrade-0.8.1.1.1-0.8.1.1.2.php
@@ -0,0 +1,37 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Api
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $this Mage_Core_Model_Resource_Setup */
+$this->startSetup();
+
+$this->getConnection()->changeColumn(
+    $this->getTable('api/user'),
+    'api_key',
+    'api_key',
+    'VARCHAR(255) NOT NULL DEFAULT \'\' COMMENT \'Api Key\''
+);
+
+$this->endSetup();
diff --git app/code/core/Mage/Catalog/Block/Product/Abstract.php app/code/core/Mage/Catalog/Block/Product/Abstract.php
index 876524299d9..36497e0ba61 100644
--- app/code/core/Mage/Catalog/Block/Product/Abstract.php
+++ app/code/core/Mage/Catalog/Block/Product/Abstract.php
@@ -107,21 +107,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
-            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
-        }
-        $additional = array_merge(
-            $additional,
-            array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
-        );
-        if (!isset($additional['_escape'])) {
-            $additional['_escape'] = true;
-        }
-        if (!isset($additional['_query'])) {
-            $additional['_query'] = array();
-        }
-        $additional['_query']['options'] = 'cart';
-        return $this->getProductUrl($product, $additional);
+        return $this->getAddToCartUrlCustom($product, $additional);
     }
 
     /**
@@ -147,15 +133,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getSubmitUrl($product, $additional = array())
     {
-        $submitRouteData = $this->getData('submit_route_data');
-        if ($submitRouteData) {
-            $route = $submitRouteData['route'];
-            $params = isset($submitRouteData['params']) ? $submitRouteData['params'] : array();
-            $submitUrl = $this->getUrl($route, array_merge($params, $additional));
-        } else {
-            $submitUrl = $this->getAddToCartUrl($product, $additional);
-        }
-        return $submitUrl;
+        return $this->getSubmitUrlCustom($product, $additional);
     }
 
     /**
@@ -166,7 +144,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToWishlistUrl($product)
     {
-        return $this->helper('wishlist')->getAddUrl($product);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -177,7 +155,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCompareUrl($product)
     {
-        return $this->helper('catalog/product_compare')->getAddUrl($product);
+        return $this->getAddToCompareUrlCustom($product);
     }
 
     public function getMinimalQty($product)
@@ -556,6 +534,36 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $product->getCanShowPrice() !== false;
     }
 
+    /**
+     * Return link to Add to Wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('wishlist')->getAddUrlWithCustomParams($product, array(), false);
+        }
+        return $this->helper('wishlist')->getAddUrl($product);
+    }
+
+    /**
+     * Retrieve Add Product to Compare Products List URL with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCompareUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('catalog/product_compare')->getAddUrlCustom($product, false);
+        }
+        return $this->helper('catalog/product_compare')->getAddUrl($product);
+    }
+
     /**
      * If exists price template block, retrieve price blocks from it
      *
@@ -575,4 +583,64 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
 
         return $this;
     }
+
+    /**
+     * Retrieve url for add product to cart with or without Form Key
+     * Will return product view page URL if product has required options
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function  getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
+            if (!$addFormKey) {
+                return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+            }
+            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        }
+        if ($addFormKey) {
+            $additional = array_merge(
+                $additional,
+                array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
+            );
+        }
+        if (!isset($additional['_escape'])) {
+            $additional['_escape'] = true;
+        }
+        if (!isset($additional['_query'])) {
+            $additional['_query'] = array();
+        }
+        $additional['_query']['options'] = 'cart';
+        return $this->getProductUrl($product, $additional);
+    }
+
+    /**
+     * Retrieves url for form submitting:
+     * some objects can use setSubmitRouteData() to set route and params for form submitting,
+     * otherwise default url will be used with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getSubmitUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        $submitRouteData = $this->getData('submit_route_data');
+        if ($submitRouteData) {
+            $route = $submitRouteData['route'];
+            $params = isset($submitRouteData['params']) ? $submitRouteData['params'] : array();
+            $submitUrl = $this->getUrl($route, array_merge($params, $additional));
+        } else {
+            if ($addFormKey) {
+                $submitUrl = $this->getAddToCartUrl($product, $additional);
+            } else {
+                $submitUrl = $this->getAddToCartUrlCustom($product, $additional, false);
+            }
+        }
+        return $submitUrl;
+    }
 }
diff --git app/code/core/Mage/Catalog/Block/Product/Compare/List.php app/code/core/Mage/Catalog/Block/Product/Compare/List.php
index 43dc1e99409..cc7df973ecc 100644
--- app/code/core/Mage/Catalog/Block/Product/Compare/List.php
+++ app/code/core/Mage/Catalog/Block/Product/Compare/List.php
@@ -63,14 +63,7 @@ class Mage_Catalog_Block_Product_Compare_List extends Mage_Catalog_Block_Product
      */
     public function getAddToWishlistUrl($product)
     {
-        $continueUrl    = Mage::helper('core')->urlEncode($this->getUrl('customer/account'));
-        $urlParamName   = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-
-        $params = array(
-            $urlParamName   => $continueUrl
-        );
-
-        return $this->helper('wishlist')->getAddUrlWithParams($product, $params);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -166,4 +159,26 @@ class Mage_Catalog_Block_Product_Compare_List extends Mage_Catalog_Block_Product
     {
         return $this->getUrl('*/*/*', array('_current'=>true, 'print'=>1));
     }
+
+    /**
+     * Retrieve url for adding product to wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        $continueUrl = Mage::helper('core')->urlEncode($this->getUrl('customer/account'));
+        $params = array(
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl
+        );
+
+        if (!$addFormKey) {
+            return $this->helper('wishlist')->getAddUrlWithCustomParams($product, $params, false);
+        }
+
+        return $this->helper('wishlist')->getAddUrlWithParams($product, $params);
+    }
+
 }
diff --git app/code/core/Mage/Catalog/Block/Product/Price.php app/code/core/Mage/Catalog/Block/Product/Price.php
index b1a2d57866a..bc3dce927be 100644
--- app/code/core/Mage/Catalog/Block/Product/Price.php
+++ app/code/core/Mage/Catalog/Block/Product/Price.php
@@ -110,4 +110,20 @@ class Mage_Catalog_Block_Product_Price extends Mage_Core_Block_Template
         }
         return parent::_toHtml();
     }
+
+    /**
+     * Retrieve url for direct adding product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+        }
+        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+    }
 }
diff --git app/code/core/Mage/Catalog/Block/Product/View.php app/code/core/Mage/Catalog/Block/Product/View.php
index 5be1145023c..ce8d0fd5621 100644
--- app/code/core/Mage/Catalog/Block/Product/View.php
+++ app/code/core/Mage/Catalog/Block/Product/View.php
@@ -230,4 +230,34 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
 
         return $qty;
     }
+
+    /**
+     * Retrieve url for direct adding product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        if (!$addFormKey && $this->hasCustomAddToCartPostUrl()) {
+            return $this->getCustomAddToCartPostUrl();
+        } elseif ($this->hasCustomAddToCartUrl()) {
+            return $this->getCustomAddToCartUrl();
+        }
+
+        if ($this->getRequest()->getParam('wishlist_next')) {
+            $additional['wishlist_next'] = 1;
+        }
+
+        $addUrlValue = Mage::getUrl('*/*/*', array('_use_rewrite' => true, '_current' => true));
+        $additional[Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED] =
+            Mage::helper('core')->urlEncode($addUrlValue);
+
+        if (!$addFormKey) {
+            return $this->helper('checkout/cart')->getAddUrlCustom($product, $additional, false);
+        }
+        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+    }
 }
diff --git app/code/core/Mage/Catalog/Helper/Product/Compare.php app/code/core/Mage/Catalog/Helper/Product/Compare.php
index 3638e3017c8..02295323a63 100644
--- app/code/core/Mage/Catalog/Helper/Product/Compare.php
+++ app/code/core/Mage/Catalog/Helper/Product/Compare.php
@@ -93,11 +93,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     protected function _getUrlParams($product)
     {
-        return array(
-            'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
+        return $this->_getUrlCustomParams($product);
     }
 
     /**
@@ -108,7 +104,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddUrl($product)
     {
-        return $this->_getUrl('catalog/product_compare/add', $this->_getUrlParams($product));
+        return $this->getAddUrlCustom($product);
     }
 
     /**
@@ -119,15 +115,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToWishlistUrl($product)
     {
-        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
-
-        $params = array(
-            'product' => $product->getId(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
-        );
-
-        return $this->_getUrl('wishlist/index/add', $params);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
     /**
@@ -138,14 +126,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToCartUrl($product)
     {
-        $beforeCompareUrl = $this->_getSingletonModel('catalog/session')->getBeforeCompareUrl();
-        $params = array(
-            'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        return $this->_getUrl('checkout/cart/add', $params);
+        return $this->getAddToCartUrlCustom($product);
     }
 
     /**
@@ -291,4 +272,71 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
     {
         return $this->_allowUsedFlat;
     }
+
+    /**
+     * Retrieve url for adding product to conpare list with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddUrlCustom($product, $addFormKey = true)
+    {
+        return $this->_getUrl('catalog/product_compare/add', $this->_getUrlCustomParams($product, $addFormKey));
+    }
+
+    /**
+     * Retrive add to wishlist url with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $params = $this->_getUrlCustomParams($product, $addFormKey, $beforeCompareUrl);
+
+        return $this->_getUrl('wishlist/index/add', $params);
+    }
+
+    /**
+     * Retrive add to cart url with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $addFormKey = true)
+    {
+        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $params = array(
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+
+        return $this->_getUrl('checkout/cart/add', $params);
+    }
+
+    /**
+     * Get parameters used for build add product to compare list urls with or without Form Key
+     *
+     * @param   Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return  array
+     */
+    protected function _getUrlCustomParams($product, $addFormKey = true, $url = null)
+    {
+        $params = array(
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($url),
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+        return $params;
+    }
 }
diff --git app/code/core/Mage/Catalog/Model/Design.php app/code/core/Mage/Catalog/Model/Design.php
index ec032a302cb..e00e5841efe 100644
--- app/code/core/Mage/Catalog/Model/Design.php
+++ app/code/core/Mage/Catalog/Model/Design.php
@@ -374,9 +374,19 @@ class Mage_Catalog_Model_Design extends Mage_Core_Model_Abstract
         $date = $object->getCustomDesignDate();
         if (array_key_exists('from', $date) && array_key_exists('to', $date)
             && Mage::app()->getLocale()->isStoreDateInInterval(null, $date['from'], $date['to'])) {
-                $settings->setCustomDesign($object->getCustomDesign())
-                    ->setPageLayout($object->getPageLayout())
-                    ->setLayoutUpdates((array)$object->getCustomLayoutUpdate());
+            $customLayout = $object->getCustomLayoutUpdate();
+            if ($customLayout) {
+                try {
+                    if (!Mage::getModel('core/layout_validator')->isValid($customLayout)) {
+                        $customLayout = '';
+                    }
+                } catch (Exception $e) {
+                    $customLayout = '';
+                }
+            }
+            $settings->setCustomDesign($object->getCustomDesign())
+                ->setPageLayout($object->getPageLayout())
+                ->setLayoutUpdates((array)$customLayout);
         }
         return $settings;
     }
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 581456c3fb5..2ab8cb2d1fe 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Catalog>
-            <version>1.4.0.0.44</version>
+            <version>1.4.0.0.44.1.2</version>
         </Mage_Catalog>
     </modules>
 
diff --git app/code/core/Mage/Catalog/sql/catalog_setup/mysql4-upgrade-1.4.0.0.44.1.1-1.4.0.0.44.1.2.php app/code/core/Mage/Catalog/sql/catalog_setup/mysql4-upgrade-1.4.0.0.44.1.1-1.4.0.0.44.1.2.php
new file mode 100644
index 00000000000..d2863c47aa5
--- /dev/null
+++ app/code/core/Mage/Catalog/sql/catalog_setup/mysql4-upgrade-1.4.0.0.44.1.1-1.4.0.0.44.1.2.php
@@ -0,0 +1,44 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Catalog
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Catalog_Model_Resource_Setup */
+$installer = $this;
+$attributeId = 'custom_layout_update';
+
+$entitiesToUpgrade = [
+    $installer->getEntityTypeId('catalog_product'),
+    $installer->getEntityTypeId('catalog_category'),
+];
+foreach ($entitiesToUpgrade as $entityTypeId) {
+    if ($this->getAttributeId($entityTypeId, $attributeId)) {
+        $installer->updateAttribute(
+            $entityTypeId,
+            $attributeId,
+            'backend_model',
+            'catalog/attribute_backend_customlayoutupdate'
+        );
+    }
+}
diff --git app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
index 2b4d8d77ac2..9c64c29ee60 100644
--- app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
+++ app/code/core/Mage/Checkout/Block/Cart/Item/Renderer.php
@@ -203,14 +203,26 @@ class Mage_Checkout_Block_Cart_Item_Renderer extends Mage_Core_Block_Template
      */
     public function getDeleteUrl()
     {
-        return $this->getUrl(
-            'checkout/cart/delete',
-            array(
-                'id'=>$this->getItem()->getId(),
-                'form_key' => Mage::getSingleton('core/session')->getFormKey(),
-                Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl()
-            )
+        return $this->getDeleteUrlCustom();
+    }
+
+    /**
+     * Get item delete url with or without Form Key
+     *
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getDeleteUrlCustom($addFormKey = true)
+    {
+        $params = array(
+            'id' => $this->getItem()->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->helper('core/url')->getEncodedUrl(),
         );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey();
+        }
+
+        return $this->getUrl('checkout/cart/delete', $params);
     }
 
     /**
diff --git app/code/core/Mage/Checkout/Helper/Cart.php app/code/core/Mage/Checkout/Helper/Cart.php
index 0b0bc9e8453..d14ef94a2a4 100644
--- app/code/core/Mage/Checkout/Helper/Cart.php
+++ app/code/core/Mage/Checkout/Helper/Cart.php
@@ -55,28 +55,7 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
      */
     public function getAddUrl($product, $additional = array())
     {
-        $routeParams = array(
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
-                ->urlEncode($this->getCurrentUrl()),
-            'product' => $product->getEntityId(),
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        if (!empty($additional)) {
-            $routeParams = array_merge($routeParams, $additional);
-        }
-
-        if ($product->hasUrlDataObject()) {
-            $routeParams['_store'] = $product->getUrlDataObject()->getStoreId();
-            $routeParams['_store_to_url'] = true;
-        }
-
-        if ($this->_getRequest()->getRouteName() == 'checkout'
-            && $this->_getRequest()->getControllerName() == 'cart') {
-            $routeParams['in_cart'] = 1;
-        }
-
-        return $this->_getUrl('checkout/cart/add', $routeParams);
+        return $this->getAddUrlCustom($product, $additional);
     }
 
     /**
@@ -175,4 +154,39 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     {
         return Mage::getStoreConfigFlag(self::XML_PATH_REDIRECT_TO_CART, $store);
     }
+
+    /**
+     * Retrieve url for add product to cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddUrlCustom($product, $additional = array(), $addFormKey = true)
+    {
+        $routeParams = array(
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
+                ->urlEncode($this->getCurrentUrl()),
+            'product' => $product->getEntityId(),
+        );
+        if ($addFormKey) {
+            $routeParams[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+        if (!empty($additional)) {
+            $routeParams = array_merge($routeParams, $additional);
+        }
+        if ($product->hasUrlDataObject()) {
+            $routeParams['_store'] = $product->getUrlDataObject()->getStoreId();
+            $routeParams['_store_to_url'] = true;
+        }
+        if (
+            $this->_getRequest()->getRouteName() == 'checkout'
+            && $this->_getRequest()->getControllerName() == 'cart'
+        ) {
+            $routeParams['in_cart'] = 1;
+        }
+
+        return $this->_getUrl('checkout/cart/add', $routeParams);
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index 3a275a34056..e860f263a01 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -57,18 +57,10 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             $quote = Mage::getModel('sales/quote')
                 ->setStoreId(Mage::app()->getStore()->getId());
-            $customerSession = Mage::getSingleton('customer/session');
-
             /* @var $quote Mage_Sales_Model_Quote */
             if ($this->getQuoteId()) {
                 $quote->loadActive($this->getQuoteId());
-                if (
-                    $quote->getId()
-                    && (
-                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
-                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
-                    )
-                ) {
+                if ($quote->getId()) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -85,15 +77,15 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
-                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
+            $customerSession = Mage::getSingleton('customer/session');
+
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn()) {
                     $quote->loadByCustomer($customerSession->getCustomer());
-                    $quote->setCustomer($customerSession->getCustomer());
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Cms/Block/Widget/Block.php app/code/core/Mage/Cms/Block/Widget/Block.php
index 15b8b623c7b..72d84a0e51c 100644
--- app/code/core/Mage/Cms/Block/Widget/Block.php
+++ app/code/core/Mage/Cms/Block/Widget/Block.php
@@ -51,9 +51,25 @@ class Mage_Cms_Block_Widget_Block extends Mage_Core_Block_Template implements Ma
                 /* @var $helper Mage_Cms_Helper_Data */
                 $helper = Mage::helper('cms');
                 $processor = $helper->getBlockTemplateProcessor();
-                $this->setText($processor->filter($block->getContent()));
+                if ($this->isRequestFromAdminArea()) {
+                    $this->setText($processor->filter(
+                        Mage::getSingleton('core/input_filter_maliciousCode')->filter($block->getContent())
+                    ));
+                } else {
+                    $this->setText($processor->filter($block->getContent()));
+                }
             }
         }
         return $this;
     }
+
+    /**
+     * Check is request goes from admin area
+     *
+     * @return bool
+     */
+    public function isRequestFromAdminArea()
+    {
+        return $this->getRequest()->getRouteName() === Mage_Core_Model_App_Area::AREA_ADMINHTML;
+    }
 }
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 6d674a2297e..d8aa2c6f748 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -1200,6 +1200,16 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
         return $this->getData('cache_lifetime');
     }
 
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return Mage::getSingleton('core/session')->getFormKey();
+    }
+
     /**
      * Load block html from cache storage
      *
@@ -1227,4 +1237,14 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
         Mage::app()->saveCache($data, $this->getCacheKey(), $this->getCacheTags(), $this->getCacheLifetime());
         return $this;
     }
+
+    /**
+     * Checks is request Url is secure
+     *
+     * @return bool
+     */
+    protected function _isSecure()
+    {
+        return Mage::app()->getFrontController()->getRequest()->isSecure();
+    }
 }
diff --git app/code/core/Mage/Core/Controller/Request/Http.php app/code/core/Mage/Core/Controller/Request/Http.php
index 18733b15e9a..f7b5d3a3151 100644
--- app/code/core/Mage/Core/Controller/Request/Http.php
+++ app/code/core/Mage/Core/Controller/Request/Http.php
@@ -261,9 +261,9 @@ class Mage_Core_Controller_Request_Http extends Zend_Controller_Request_Http
         return $path;
     }
 
-    public function getBaseUrl()
+    public function getBaseUrl($raw = false)
     {
-        $url = parent::getBaseUrl();
+        $url = parent::getBaseUrl($raw);
         $url = str_replace('\\', '/', $url);
         return $url;
     }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index 36eb5369a4d..d64d15f7b13 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -249,11 +249,41 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         return $this->getEncryptor()->getHash($password, $salt);
     }
 
+    /**
+     *  Generate password hash for user
+     *
+     * @param string $password
+     * @param mixed $salt
+     * @return string
+     */
+    public function getHashPassword($password, $salt = false)
+    {
+        $encryptionModel = $this->getEncryptor();
+        $latestVersionHash = $this->getVersionHash($encryptionModel);
+        if ($latestVersionHash == $encryptionModel::HASH_VERSION_SHA512) {
+            return $this->getEncryptor()->getHashPassword($password, $salt);
+        }
+        return $this->getEncryptor()->getHashPassword($password, Mage_Admin_Model_User::HASH_SALT_EMPTY);
+    }
+
     public function validateHash($password, $hash)
     {
         return $this->getEncryptor()->validateHash($password, $hash);
     }
 
+    /**
+     * Get encryption method depending on the presence of the function - password_hash.
+     *
+     * @param Mage_Core_Model_Encryption $encryptionModel
+     * @return int
+     */
+    public function getVersionHash(Mage_Core_Model_Encryption $encryptionModel)
+    {
+        return function_exists('password_hash')
+            ? $encryptionModel::HASH_VERSION_LATEST
+            : $encryptionModel::HASH_VERSION_SHA512;
+    }
+
     /**
      * Retrieve store identifier
      *
diff --git app/code/core/Mage/Core/Helper/String.php app/code/core/Mage/Core/Helper/String.php
index ecc75e38b39..98955893508 100644
--- app/code/core/Mage/Core/Helper/String.php
+++ app/code/core/Mage/Core/Helper/String.php
@@ -299,4 +299,36 @@ class Mage_Core_Helper_String extends Mage_Core_Helper_Abstract
     {
         return iconv_strpos($haystack, $needle, $offset, self::ICONV_CHARSET);
     }
+
+    /**
+     * Detect serialization of data Array or Object
+     *
+     * @param mixed $data
+     * @return bool
+     */
+    public function isSerializedArrayOrObject($data)
+    {
+        $pattern =
+            '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{(s:\d+:\"|i:\d+;)/';
+        return is_string($data) && preg_match($pattern, $data);
+    }
+
+    /**
+     * Validate is Serialized Data Object in string
+     *
+     * @param string $str
+     * @return bool
+     */
+    public function validateSerializedObject($str)
+    {
+        if ($this->isSerializedArrayOrObject($str)) {
+            try {
+                $this->unserialize($str);
+            } catch (Exception $e) {
+                return false;
+            }
+        }
+
+        return true;
+    }
 }
diff --git app/code/core/Mage/Core/Model/App.php app/code/core/Mage/Core/Model/App.php
index 06628e0b418..6b684298ea3 100644
--- app/code/core/Mage/Core/Model/App.php
+++ app/code/core/Mage/Core/Model/App.php
@@ -65,6 +65,22 @@ class Mage_Core_Model_App
      */
     const ADMIN_STORE_ID = 0;
 
+    /**
+     * The absolute minimum of password length for all types of passwords
+     *
+     * With changing this value also need to change:
+     * 1. in `js/prototype/validation.js` declarations `var minLength = 7;` in two places;
+     * 2. in `app/code/core/Mage/Customer/etc/system.xml`
+     *    comments for fields `min_password_length` and `min_admin_password_length`
+     *    `<comment>Please enter a number 7 or greater in this field.</comment>`;
+     * 3. in `app/code/core/Mage/Customer/etc/config.xml` value `<min_password_length>7</min_password_length>`
+     *    and, maybe, value `<min_admin_password_length>14</min_admin_password_length>`
+     *    (if the absolute minimum of password length is higher then this value);
+     * 4. maybe, the value of deprecated `const MIN_PASSWORD_LENGTH` in `app/code/core/Mage/Admin/Model/User.php`,
+     *    (if the absolute minimum of password length is higher then this value).
+     */
+    const ABSOLUTE_MIN_PASSWORD_LENGTH = 7;
+
     /**
      * Application loaded areas array
      *
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 4919a4527bc..2a8b7c59c7e 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -33,6 +33,14 @@
  */
 class Mage_Core_Model_Encryption
 {
+    const HASH_VERSION_MD5    = 0;
+    const HASH_VERSION_SHA512 = 2;
+
+    /**
+     * Encryption method bcrypt
+     */
+    const HASH_VERSION_LATEST = 3;
+
     /**
      * @var Varien_Crypt_Mcrypt
      */
@@ -74,14 +82,37 @@ class Mage_Core_Model_Encryption
         return $salt === false ? $this->hash($password) : $this->hash($salt . $password) . ':' . $salt;
     }
 
+    /**
+     * Generate hash for customer password
+     *
+     * @param string $password
+     * @param mixed $salt
+     * @return string
+     */
+    public function getHashPassword($password, $salt = null)
+    {
+        if (is_integer($salt)) {
+            $salt = $this->_helper->getRandomString($salt);
+        }
+        return (bool) $salt
+            ? $this->hash($salt . $password, $this->_helper->getVersionHash($this)) . ':' . $salt
+            : $this->hash($password, $this->_helper->getVersionHash($this));
+    }
+
     /**
      * Hash a string
      *
      * @param string $data
-     * @return string
+     * @param int $version
+     * @return bool|string
      */
-    public function hash($data)
+    public function hash($data, $version = self::HASH_VERSION_MD5)
     {
+        if (self::HASH_VERSION_LATEST === $version && $version === $this->_helper->getVersionHash($this)) {
+            return password_hash($data, PASSWORD_DEFAULT);
+        } elseif (self::HASH_VERSION_SHA512 == $version) {
+            return hash('sha512', $data);
+        }
         return md5($data);
     }
 
@@ -95,14 +126,31 @@ class Mage_Core_Model_Encryption
      */
     public function validateHash($password, $hash)
     {
-        $hashArr = explode(':', $hash);
-        switch (count($hashArr)) {
-            case 1:
-                return hash_equals($this->hash($password), $hash);
-            case 2:
-                return hash_equals($this->hash($hashArr[1] . $password),  $hashArr[0]);
+        return $this->validateHashByVersion($password, $hash, self::HASH_VERSION_LATEST)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_SHA512)
+            || $this->validateHashByVersion($password, $hash, self::HASH_VERSION_MD5);
+    }
+
+    /**
+     * Validate hash by specified version
+     *
+     * @param string $password
+     * @param string $hash
+     * @param int $version
+     * @return bool
+     */
+    public function validateHashByVersion($password, $hash, $version = self::HASH_VERSION_MD5)
+    {
+        if ($version == self::HASH_VERSION_LATEST && $version == $this->_helper->getVersionHash($this)) {
+            return password_verify($password, $hash);
+        }
+        // look for salt
+        $hashArr = explode(':', $hash, 2);
+        if (1 === count($hashArr)) {
+            return hash_equals($this->hash($password, $version), $hash);
         }
-        Mage::throwException('Invalid hash.');
+        list($hash, $salt) = $hashArr;
+        return hash_equals($this->hash($salt . $password, $version), $hash);
     }
 
     /**
diff --git app/code/core/Mage/Core/Model/File/Uploader.php app/code/core/Mage/Core/Model/File/Uploader.php
index f92b3d47527..2190e615547 100644
--- app/code/core/Mage/Core/Model/File/Uploader.php
+++ app/code/core/Mage/Core/Model/File/Uploader.php
@@ -34,6 +34,13 @@
  */
 class Mage_Core_Model_File_Uploader extends Varien_File_Uploader
 {
+    /**
+     * Max file name length
+     *
+     * @var int
+     */
+    protected $_fileNameMaxLength = 200;
+
     /**
      * Save file to storage
      *
@@ -77,4 +84,25 @@ class Mage_Core_Model_File_Uploader extends Varien_File_Uploader
 
         return parent::checkAllowedExtension($extension);
     }
+
+    /**
+     * Used to save uploaded file into destination folder with
+     * original or new file name (if specified).
+     * Added file name length validation.
+     *
+     * @param string $destinationFolder
+     * @param string|null $newFileName
+     * @return bool|void
+     * @throws Exception
+     */
+    public function save($destinationFolder, $newFileName = null)
+    {
+        $fileName = isset($newFileName) ? $newFileName : $this->_file['name'];
+        if (strlen($fileName) > $this->_fileNameMaxLength) {
+            throw new Exception(
+                Mage::helper('core')->__("File name is too long. Maximum length is %s.", $this->_fileNameMaxLength)
+            );
+        }
+        return parent::save($destinationFolder, $newFileName);
+    }
 }
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 9b9e9d817d6..bbdf6d1e424 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -20,8 +20,8 @@
  *
  * @category    Mage
  * @package     Mage_Core
- * @copyright   Copyright (c) 2010 Magento Inc. (http://www.magentocommerce.com)
- * @license     http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
  */
 
 /**
@@ -50,11 +50,13 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         //js in the style attribute
         '/style=[^<]*((expression\s*?\([^<]*?\))|(behavior\s*:))[^<]*(?=\>)/Uis',
         //js attributes
-        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror)\s*=[^>]*(?=\>)/Uis',
+        '/(ondblclick|onclick|onkeydown|onkeypress|onkeyup|onmousedown|onmousemove|onmouseout|onmouseover|onmouseup|onload|onunload|onerror|onanimationstart)\s*=[^>]*(?=\>)/Uis',
         //tags
         '/<\/?(script|meta|link|frame|iframe).*>/Uis',
         //base64 usage
         '/src\s*=[^<]*base64[^<]*(?=\>)/Uis',
+        //data attribute
+        '/(data(\\\\x3a|:|%3A)(.+?(?=")|.+?(?=\')))/is',
     );
 
     /**
@@ -99,4 +101,64 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
         $this->_expressions = $expressions;
         return $this;
     }
+
+    /**
+     * The filter adds safe attributes to the link
+     *
+     * @param string $html
+     * @param bool $removeWrapper flag for remove wrapper tags: Doctype, html, body
+     * @return string
+     * @throws Mage_Core_Exception
+     */
+    public function linkFilter($html, $removeWrapper = true)
+    {
+        if (stristr($html, '<a ') === false) {
+            return $html;
+        }
+
+        $libXmlErrorsState = libxml_use_internal_errors(true);
+        $dom = $this->_initDOMDocument();
+        if (!$dom->loadHTML($html)) {
+            Mage::throwException(Mage::helper('core')->__('HTML filtration has failed.'));
+        }
+
+        $relAttributeDefaultItems = array('noopener', 'noreferrer');
+        /** @var DOMElement $linkItem */
+        foreach ($dom->getElementsByTagName('a') as $linkItem) {
+            $relAttributeItems = array();
+            $relAttributeCurrentValue = $linkItem->getAttribute('rel');
+            if (!empty($relAttributeCurrentValue)) {
+                $relAttributeItems = explode(' ', $relAttributeCurrentValue);
+            }
+            $relAttributeItems = array_unique(array_merge($relAttributeItems, $relAttributeDefaultItems));
+            $linkItem->setAttribute('rel', implode(' ', $relAttributeItems));
+            $linkItem->setAttribute('target', '_blank');
+        }
+
+        if (!$html = $dom->saveHTML()) {
+            Mage::throwException(Mage::helper('core')->__('HTML filtration has failed.'));
+        }
+
+        if ($removeWrapper) {
+            $html = preg_replace('/<(?:!DOCTYPE|\/?(?:html|body))[^>]*>\s*/i', '', $html);
+        }
+
+        libxml_use_internal_errors($libXmlErrorsState);
+
+        return $html;
+    }
+
+    /**
+     * Initialize built-in DOM parser instance
+     *
+     * @return DOMDocument
+     */
+    protected function _initDOMDocument()
+    {
+        $dom = new DOMDocument();
+        $dom->strictErrorChecking = false;
+        $dom->recover = false;
+
+        return $dom;
+    }
 }
diff --git app/code/core/Mage/Core/Model/Layout/Validator.php app/code/core/Mage/Core/Model/Layout/Validator.php
new file mode 100644
index 00000000000..94497b9f246
--- /dev/null
+++ app/code/core/Mage/Core/Model/Layout/Validator.php
@@ -0,0 +1,258 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/**
+ * Validator for custom layout update
+ *
+ * Validator checked XML validation and protected expressions
+ *
+ * @category   Mage
+ * @package    Mage_Core
+ * @author     Magento Core Team <core@magentocommerce.com>
+ */
+class Mage_Core_Model_Layout_Validator extends Zend_Validate_Abstract
+{
+    const XML_PATH_LAYOUT_DISALLOWED_BLOCKS       = 'validators/custom_layout/disallowed_block';
+    const XML_INVALID                             = 'invalidXml';
+    const INVALID_TEMPLATE_PATH                   = 'invalidTemplatePath';
+    const INVALID_BLOCK_NAME                      = 'invalidBlockName';
+    const PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR = 'protectedAttrHelperInActionVar';
+    const INVALID_XML_OBJECT_EXCEPTION            = 'invalidXmlObject';
+
+    /**
+     * The Varien SimpleXml object
+     *
+     * @var Varien_Simplexml_Element
+     */
+    protected $_value;
+
+    /**
+     * XPath expression for checking layout update
+     *
+     * @var array
+     */
+    protected $_disallowedXPathExpressions = array(
+        '*//template',
+        '*//@template',
+        '//*[@method=\'setTemplate\']',
+        '//*[@method=\'setDataUsingMethod\']//*[contains(translate(text(),
+        \'ABCDEFGHIJKLMNOPQRSTUVWXYZ\', \'abcdefghijklmnopqrstuvwxyz\'), \'template\')]/../*',
+    );
+
+    /**
+     * @var string
+     */
+    protected $_xpathBlockValidationExpression = '';
+
+    /**
+     * Disallowed template name
+     *
+     * @var array
+     */
+    protected $_disallowedBlock = array();
+
+    /**
+     * Protected expressions
+     *
+     * @var array
+     */
+    protected $_protectedExpressions = array(
+        self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR => '//action/*[@helper]',
+    );
+
+    /**
+     * Construct
+     */
+    public function __construct()
+    {
+        $this->_initMessageTemplates();
+        $this->getDisallowedBlocks();
+    }
+
+    /**
+     * Initialize messages templates with translating
+     *
+     * @return Mage_Core_Model_Layout_Validator
+     */
+    protected function _initMessageTemplates()
+    {
+        if (!$this->_messageTemplates) {
+            $this->_messageTemplates = array(
+                self::PROTECTED_ATTR_HELPER_IN_TAG_ACTION_VAR =>
+                    Mage::helper('core')->__('Helper attributes should not be used in custom layout updates.'),
+                self::XML_INVALID => Mage::helper('core')->__('XML data is invalid.'),
+                self::INVALID_TEMPLATE_PATH => Mage::helper('core')->__(
+                    'Invalid template path used in layout update.'
+                ),
+                self::INVALID_BLOCK_NAME => Mage::helper('core')->__('Disallowed block name for frontend.'),
+                self::INVALID_XML_OBJECT_EXCEPTION =>
+                    Mage::helper('core')->__('XML object is not instance of "Varien_Simplexml_Element".'),
+            );
+        }
+        return $this;
+    }
+
+    /**
+     * @return array
+     */
+    public function getDisallowedBlocks()
+    {
+        if (!count($this->_disallowedBlock)) {
+            $disallowedBlockConfig = $this->_getDisallowedBlockConfigValue();
+            if (is_array($disallowedBlockConfig)) {
+                foreach ($disallowedBlockConfig as $blockName => $value) {
+                    $this->_disallowedBlock[] = $blockName;
+                }
+            }
+        }
+        return $this->_disallowedBlock;
+    }
+
+    /**
+     * @return mixed
+     */
+    protected function _getDisallowedBlockConfigValue()
+    {
+        return Mage::getStoreConfig(self::XML_PATH_LAYOUT_DISALLOWED_BLOCKS);
+    }
+
+    /**
+     * Returns true if and only if $value meets the validation requirements
+     *
+     * If $value fails validation, then this method returns false, and
+     * getMessages() will return an array of messages that explain why the
+     * validation failed.
+     *
+     * @throws Exception            Throw exception when xml object is not
+     *                              instance of Varien_Simplexml_Element
+     * @param Varien_Simplexml_Element|string $value
+     * @return bool
+     */
+    public function isValid($value)
+    {
+        if (is_string($value)) {
+            $value = trim($value);
+            try {
+                $value = new Varien_Simplexml_Element('<config>' . $value . '</config>');
+            } catch (Exception $e) {
+                $this->_error(self::XML_INVALID);
+                return false;
+            }
+        } elseif (!($value instanceof Varien_Simplexml_Element)) {
+            throw new Exception($this->_messageTemplates[self::INVALID_XML_OBJECT_EXCEPTION]);
+        }
+        if ($value->xpath($this->getXpathBlockValidationExpression())) {
+            $this->_error(self::INVALID_BLOCK_NAME);
+            return false;
+        }
+        // if layout update declare custom templates then validate their paths
+        if ($templatePaths = $value->xpath($this->getXpathValidationExpression())) {
+            try {
+                $this->validateTemplatePath($templatePaths);
+            } catch (Exception $e) {
+                $this->_error(self::INVALID_TEMPLATE_PATH);
+                return false;
+            }
+        }
+        $this->_setValue($value);
+
+        foreach ($this->_protectedExpressions as $key => $xpr) {
+            if ($this->_value->xpath($xpr)) {
+                $this->_error($key);
+                return false;
+            }
+        }
+        return true;
+    }
+
+    /**
+     * @return array
+     */
+    public function getProtectedExpressions()
+    {
+        return $this->_protectedExpressions;
+    }
+
+    /**
+     * Returns xPath for validate incorrect path to template
+     *
+     * @return string xPath for validate incorrect path to template
+     */
+    public function getXpathValidationExpression()
+    {
+        return implode(" | ", $this->_disallowedXPathExpressions);
+    }
+
+    /**
+     * @return array
+     */
+    public function getDisallowedXpathValidationExpression()
+    {
+        return $this->_disallowedXPathExpressions;
+    }
+
+    /**
+     * Returns xPath for validate incorrect block name
+     *
+     * @return string xPath for validate incorrect block name
+     */
+    public function getXpathBlockValidationExpression()
+    {
+        if (!$this->_xpathBlockValidationExpression) {
+            if (count($this->_disallowedBlock)) {
+                foreach ($this->_disallowedBlock as $key => $value) {
+                    $this->_xpathBlockValidationExpression .= $key > 0 ? " | " : '';
+                    $this->_xpathBlockValidationExpression .=
+                        "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
+                    $this->_xpathBlockValidationExpression .=
+                        "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
+                }
+            }
+        }
+        return $this->_xpathBlockValidationExpression;
+    }
+
+    /**
+     * Validate template path for preventing access to the directory above
+     * If template path value has "../"
+     *
+     * @throws Exception
+     *
+     * @param $templatePaths | array
+     */
+    public function validateTemplatePath(array $templatePaths)
+    {
+        /** @var $path Varien_Simplexml_Element */
+        foreach ($templatePaths as $path) {
+            if ($path->hasChildren()) {
+                $path = stripcslashes(trim((string) $path->children(), '"'));
+            }
+            if (strpos($path, '..' . DS) !== false) {
+                throw new Exception();
+            }
+        }
+    }
+}
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index 4ffc166c686..801189ef3cd 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -28,7 +28,7 @@
 <config>
     <modules>
         <Mage_Core>
-             <version>0.8.28.1.3</version>
+             <version>0.8.28.1.5</version>
         </Mage_Core>
     </modules>
 
@@ -365,6 +365,7 @@
             <security>
                 <use_form_key>1</use_form_key>
                 <extensions_compatibility_mode>1</extensions_compatibility_mode>
+                <secure_system_configuration_save_disabled>0</secure_system_configuration_save_disabled>
             </security>
         </admin>
 
@@ -422,6 +423,13 @@
                 <admin_user_create></admin_user_create>
             </additional_notification_emails>
         </general>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Core_Block_Template_Zend/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
     </default>
     <stores> <!-- declare routers for installation process -->
         <default>
diff --git app/code/core/Mage/Core/etc/system.xml app/code/core/Mage/Core/etc/system.xml
index c19a1cad41f..ec6dd99f694 100644
--- app/code/core/Mage/Core/etc/system.xml
+++ app/code/core/Mage/Core/etc/system.xml
@@ -119,6 +119,7 @@
                     <show_in_default>1</show_in_default>
                     <show_in_website>1</show_in_website>
                     <show_in_store>1</show_in_store>
+                    <dynamic_group>1</dynamic_group>
                 </modules_disable_output>
             </groups>
         </advanced>
diff --git app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.3-0.8.28.1.4.php app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.3-0.8.28.1.4.php
new file mode 100644
index 00000000000..d43552d82d6
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.3-0.8.28.1.4.php
@@ -0,0 +1,35 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
+
+$installer->startSetup();
+$connection = $installer->getConnection();
+
+$connection->addColumn($installer->getTable('core_config_data'), 'updated_at', Varien_Db_Ddl_Table::TYPE_TIMESTAMP);
+
+$installer->endSetup();
diff --git app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.4-0.8.28.1.5.php app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.4-0.8.28.1.5.php
new file mode 100644
index 00000000000..3b5237d28aa
--- /dev/null
+++ app/code/core/Mage/Core/sql/core_setup/mysql4-upgrade-0.8.28.1.4-0.8.28.1.5.php
@@ -0,0 +1,28 @@
+<?php
+/**
+ * Magento
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Core
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
+ */
+
+/* @var $installer Mage_Core_Model_Resource_Setup */
+$installer = $this;
diff --git app/code/core/Mage/Customer/Block/Address/Renderer/Default.php app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
index 2e57743f87d..71bb9cbd4ce 100644
--- app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
+++ app/code/core/Mage/Customer/Block/Address/Renderer/Default.php
@@ -66,7 +66,13 @@ class Mage_Customer_Block_Address_Renderer_Default extends Mage_Core_Block_Abstr
     public function getFormat(Mage_Customer_Model_Address_Abstract $address=null)
     {
         $countryFormat = is_null($address) ? false : $address->getCountryModel()->getFormat($this->getType()->getCode());
-        $format = $countryFormat ? $countryFormat->getFormat() : $this->getType()->getDefaultFormat();
+        if ($countryFormat) {
+            $format = $countryFormat->getFormat();
+        } else {
+            $regExp = "/^[^()\n]*+(\((?>[^()\n]|(?1))*+\)[^()\n]*+)++$|^[^()]+?$/m";
+            preg_match_all($regExp, $this->getType()->getDefaultFormat(), $matches, PREG_SET_ORDER);
+            $format = count($matches) ? $this->_prepareAddressTemplateData($this->getType()->getDefaultFormat()) : null;
+        }
         return $format;
     }
 
@@ -128,9 +134,25 @@ class Mage_Customer_Block_Address_Renderer_Default extends Mage_Core_Block_Abstr
         }
 
         $formater->setVariables($data);
-
-        $format = !is_null($format) ? $format : $this->getFormat($address);
+        $format = !is_null($format) ? $format : $this->_prepareAddressTemplateData($this->getFormat($address));
 
         return $formater->filter($format);
     }
+
+    /**
+     * Get address template data without url and js code
+     * @param $data
+     * @return string
+     */
+    protected function _prepareAddressTemplateData($data)
+    {
+        $result = '';
+        if (is_string($data)) {
+            $urlRegExp = "@(https?://([-\w\.]+[-\w])+(:\d+)?(/([\w/_\.#-]*(\?\S+)?[^\.\s])?)?)@";
+            /** @var $maliciousCodeFilter Mage_Core_Model_Input_Filter_MaliciousCode */
+            $maliciousCodeFilter = Mage::getSingleton('core/input_filter_maliciousCode');
+            $result = preg_replace($urlRegExp, ' ', $maliciousCodeFilter->filter($data));
+        }
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Customer/Block/Form/Register.php app/code/core/Mage/Customer/Block/Form/Register.php
index f6948b08ed8..a26b4a4f3bf 100644
--- app/code/core/Mage/Customer/Block/Form/Register.php
+++ app/code/core/Mage/Customer/Block/Form/Register.php
@@ -159,4 +159,14 @@ class Mage_Customer_Block_Form_Register extends Mage_Directory_Block_Data
 
         return $this;
     }
+
+    /**
+     * Retrieve minimum length of customer password
+     *
+     * @return int
+     */
+    public function getMinPasswordLength()
+    {
+        return Mage::getModel('customer/customer')->getMinPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Customer/Model/Customer.php app/code/core/Mage/Customer/Model/Customer.php
index e0357c46c22..95b9985e6ce 100644
--- app/code/core/Mage/Customer/Model/Customer.php
+++ app/code/core/Mage/Customer/Model/Customer.php
@@ -41,6 +41,17 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
     const XML_PATH_CONFIRMED_EMAIL_TEMPLATE     = 'customer/create_account/email_confirmed_template';
     const XML_PATH_GENERATE_HUMAN_FRIENDLY_ID   = 'customer/create_account/generate_human_friendly_id';
 
+    /**
+     * Minimum Password Length
+     * @deprecated Use getMinPasswordLength() method instead
+     */
+    const MINIMUM_PASSWORD_LENGTH = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+
+    /**
+     * Configuration path for minimum length of password
+     */
+    const XML_PATH_MIN_PASSWORD_LENGTH = 'customer/password/min_password_length';
+
     /**
      * Maximum Password Length
      */
@@ -330,7 +341,7 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
      */
     public function hashPassword($password, $salt=null)
     {
-        return Mage::helper('core')->getHash($password, !is_null($salt) ? $salt : 2);
+        return Mage::helper('core')->getHashPassword(trim($password), (bool) $salt ? $salt : Mage_Admin_Model_User::HASH_SALT_LENGTH);
     }
 
     /**
@@ -341,6 +352,10 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
      */
     public function generatePassword($length=6)
     {
+        $minPasswordLength = $this->getMinPasswordLength();
+        if ($minPasswordLength > $length) {
+            $length = $minPasswordLength;
+        }
         return Mage::helper('core')->getRandomString($length);
     }
 
@@ -735,8 +750,9 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         if (!$this->getId() && !Zend_Validate::is($password , 'NotEmpty')) {
             $errors[] = $customerHelper->__('The password cannot be empty.');
         }
-        if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array(6))) {
-            $errors[] = $customerHelper->__('The minimum password length is %s', 6);
+        $minPasswordLength = $this->getMinPasswordLength();
+        if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array($minPasswordLength))) {
+            $errors[] = $customerHelper->__('The minimum password length is %s', $minPasswordLength);
         }
         if (strlen($password) && !Zend_Validate::is($password, 'StringLength', array('max' => self::MAXIMUM_PASSWORD_LENGTH))) {
             $errors[] = Mage::helper('customer')
@@ -1183,4 +1199,16 @@ class Mage_Customer_Model_Customer extends Mage_Core_Model_Abstract
         }
         return $defaultStoreId;
     }
+
+    /**
+     * Retrieve minimum length of password
+     *
+     * @return int
+     */
+    public function getMinPasswordLength()
+    {
+        $minLength = (int)Mage::getStoreConfig(self::XML_PATH_MIN_PASSWORD_LENGTH);
+        $absoluteMinLength = Mage_Core_Model_App::ABSOLUTE_MIN_PASSWORD_LENGTH;
+        return ($minLength < $absoluteMinLength) ? $absoluteMinLength : $minLength;
+    }
 }
diff --git app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
index ff7ecf2eb79..835d49a1798 100644
--- app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
+++ app/code/core/Mage/Customer/Model/Customer/Attribute/Backend/Password.php
@@ -43,8 +43,12 @@ class Mage_Customer_Model_Customer_Attribute_Backend_Password extends Mage_Eav_M
         $password = trim($object->getPassword());
         $len = Mage::helper('core/string')->strlen($password);
         if ($len) {
-             if ($len < 6) {
-                Mage::throwException(Mage::helper('customer')->__('The password must have at least 6 characters. Leading or trailing spaces will be ignored.'));
+            $minPasswordLength = Mage::getModel('customer/customer')->getMinPasswordLength();
+            if ($len < $minPasswordLength) {
+                Mage::throwException(Mage::helper('customer')->__(
+                    'The password must have at least %d characters. Leading or trailing spaces will be ignored.',
+                    $minPasswordLength
+                ));
             }
             $object->setPasswordHash($object->hashPassword($password));
         }
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 75300c98f8a..1bf56952af6 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -767,14 +767,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $newPass    = $this->getRequest()->getPost('password');
                     $confPass   = $this->getRequest()->getPost('confirmation');
 
-                    $oldPass = $this->_getSession()->getCustomer()->getPasswordHash();
-                    if ($this->_getHelper('core/string')->strpos($oldPass, ':')) {
-                        list($_salt, $salt) = explode(':', $oldPass);
-                    } else {
-                        $salt = false;
-                    }
-
-                    if ($customer->hashPassword($currPass, $salt) == $oldPass) {
+                    if ($customer->validatePassword($currPass)) {
                         if (strlen($newPass)) {
                             /**
                              * Set entered password and its confirmation - they
diff --git app/code/core/Mage/Customer/etc/config.xml app/code/core/Mage/Customer/etc/config.xml
index 51a04781079..a946ad1d50e 100644
--- app/code/core/Mage/Customer/etc/config.xml
+++ app/code/core/Mage/Customer/etc/config.xml
@@ -259,6 +259,7 @@
             <password>
                 <forgot_email_identity>support</forgot_email_identity>
                 <forgot_email_template>customer_password_forgot_email_template</forgot_email_template>
+                <min_password_length>7</min_password_length>
             </password>
 
             <address>
@@ -311,5 +312,10 @@ T: {{var telephone}}
                 <js_template><![CDATA[#{prefix} #{firstname} #{middlename} #{lastname} #{suffix}<br/>#{company}<br/>#{street0}<br/>#{street1}<br/>#{street2}<br/>#{street3}<br/>#{city}, #{region}, #{postcode}<br/>#{country_id}<br/>T: #{telephone}<br/>F: #{fax}]]></js_template>
             </address_templates>
         </customer>
+        <admin>
+            <security>
+                <min_admin_password_length>14</min_admin_password_length>
+            </security>
+        </admin>
     </default>
 </config>
diff --git app/code/core/Mage/Customer/etc/system.xml app/code/core/Mage/Customer/etc/system.xml
index e00ded1a2aa..bf8bc17390d 100644
--- app/code/core/Mage/Customer/etc/system.xml
+++ app/code/core/Mage/Customer/etc/system.xml
@@ -188,6 +188,17 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </forgot_email_template>
+                        <min_password_length translate="label comment">
+                            <label>Minimum password length</label>
+                            <comment>Please enter a number 7 or greater in this field.</comment>
+                            <frontend_type>text</frontend_type>
+                            <validate>required-entry validate-digits validate-digits-range digits-range-7-</validate>
+                            <backend_model>adminhtml/system_config_backend_passwordlength</backend_model>
+                            <sort_order>60</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </min_password_length>
                     </fields>
                 </password>
                 <address translate="label">
@@ -358,5 +369,24 @@
                 </address_templates>
             </groups>
         </customer>
+        <admin>
+            <groups>
+                <security>
+                    <fields>
+                        <min_admin_password_length translate="label comment">
+                            <label>Minimum admin password length</label>
+                            <comment>Please enter a number 7 or greater in this field.</comment>
+                            <frontend_type>text</frontend_type>
+                            <validate>required-entry validate-digits validate-digits-range digits-range-7-</validate>
+                            <backend_model>adminhtml/system_config_backend_passwordlength</backend_model>
+                            <sort_order>170</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </min_admin_password_length>
+                    </fields>
+                </security>
+            </groups>
+        </admin>
     </sections>
 </config>
diff --git app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
index e7ed2dfca93..70f195e5e28 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Container/Abstract.php
@@ -55,9 +55,7 @@ abstract class Mage_Dataflow_Model_Convert_Container_Abstract
      */
     protected function isSerialized($data)
     {
-        $pattern =
-            '/^a:\d+:\{(i:\d+;|s:\d+:\".+\";|N;|O:\d+:\"\w+\":\d+:\{\w:\d+:)+|^O:\d+:\"\w+\":\d+:\{(s:\d+:\"|i:\d+;)/';
-        return (is_string($data) && preg_match($pattern, $data));
+        return Mage::helper('core/string')->isSerializedArrayOrObject($data);
     }
 
     public function getVar($key, $default=null)
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
index d9612464c7f..750b812aaeb 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Csv.php
@@ -69,6 +69,7 @@ class Mage_Dataflow_Model_Convert_Parser_Csv extends Mage_Dataflow_Model_Convert
 
         if (!is_callable(array($adapter, $adapterMethod))) {
             $message = Mage::helper('dataflow')->__('Method "%s" not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')->escapeHtml($message);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
index bd033c7cf1f..9676a90626b 100644
--- app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
+++ app/code/core/Mage/Dataflow/Model/Convert/Parser/Xml/Excel.php
@@ -70,6 +70,7 @@ class Mage_Dataflow_Model_Convert_Parser_Xml_Excel extends Mage_Dataflow_Model_C
 
         if (!is_callable(array($adapter, $adapterMethod))) {
             $message = Mage::helper('dataflow')->__('Method "%s" was not defined in adapter %s.', $adapterMethod, $adapterName);
+            $message = Mage::helper('dataflow')->escapeHtml($message);
             $this->addException($message, Mage_Dataflow_Model_Convert_Exception::FATAL);
             return $this;
         }
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index 256b7dea22d..aa43618ef4d 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -34,6 +34,20 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
     const DEFAULT_EXPORT_PATH = 'var/export';
     const DEFAULT_EXPORT_FILENAME = 'export_';
 
+    /**
+     * Product table permanent attributes
+     *
+     * @var array
+     */
+    protected $_productTablePermanentAttributes = array('sku');
+
+    /**
+     * Customer table permanent attributes
+     *
+     * @var array
+     */
+    protected $_customerTablePermanentAttributes = array('email', 'website');
+
     protected function _construct()
     {
         $this->_init('dataflow/profile');
@@ -122,6 +136,9 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
             ->setProfileId($this->getId())
             ->setActionCode($this->getOrigData('profile_id') ? 'update' : 'create')
             ->save();
+        $csvParser = new Varien_File_Csv();
+        $xmlParser = new DOMDocument();
+        $newUploadedFilenames = array();
 
         if (isset($_FILES['file_1']['tmp_name']) || isset($_FILES['file_2']['tmp_name'])
         || isset($_FILES['file_3']['tmp_name'])) {
@@ -131,9 +148,58 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
                     $uploader->setAllowedExtensions(array('csv','xml'));
                     $path = Mage::app()->getConfig()->getTempVarDir() . '/import/';
                     $uploader->save($path);
-                    if ($uploadFile = $uploader->getUploadedFileName()) {
+                    $uploadFile = $uploader->getUploadedFileName();
+
+                    if ($_FILES['file_' . ($index + 1)]['type'] == "text/csv") {
+                        $fileData = $csvParser->getData($path . $uploadFile);
+                        $fileData = array_shift($fileData);
+                    } else {
+                        try {
+                            $xmlParser->loadXML(file_get_contents($path . $uploadFile));
+                            $cells = $this->getNode($xmlParser, 'Worksheet')->item(0);
+                            $cells = $this->getNode($cells, 'Row')->item(0);
+                            $cells = $this->getNode($cells, 'Cell');
+                            $fileData = array();
+                            foreach ($cells as $cell) {
+                                $fileData[] = $this->getNode($cell, 'Data')->item(0)->nodeValue;
+                            }
+                        } catch (Exception $e) {
+                            foreach ($newUploadedFilenames as $k => $v) {
+                                unlink($path . $v);
+                            }
+                            unlink($path . $uploadFile);
+                            Mage::throwException(
+                                Mage::helper('Dataflow')->__(
+                                    'Upload failed. Wrong data format in file: %s.',
+                                    $uploadFile
+                                )
+                            );
+                        }
+                    }
+
+                    if ($this->_data['entity_type'] == 'customer') {
+                        $attributes = $this->_customerTablePermanentAttributes;
+                    } else {
+                        $attributes = $this->_productTablePermanentAttributes;
+                    }
+                    $colsAbsent = array_diff($attributes, $fileData);
+                    if ($colsAbsent) {
+                        foreach ($newUploadedFilenames as $k => $v) {
+                            unlink($path . $v);
+                        }
+                        unlink($path . $uploadFile);
+                        Mage::throwException(
+                            Mage::helper('Dataflow')->__(
+                                'Upload failed. Can not find required columns: %s in file %s.',
+                                implode(', ', $colsAbsent),
+                                $uploadFile
+                            )
+                        );
+                    }
+                    if ($uploadFile) {
                         $newFilename = 'import-' . date('YmdHis') . '-' . ($index+1) . '_' . $uploadFile;
                         rename($path . $uploadFile, $path . $newFilename);
+                        $newUploadedFilenames[] = $newFilename;
                     }
                 }
                 //BOM deleting for UTF files
@@ -402,4 +468,20 @@ echo "<xmp>" . $xml . "</xmp>";
 die;*/
         return $this;
     }
+
+    /**
+     * Get node from xml object
+     *
+     * @param object $xmlObject
+     * @param string $nodeName
+     * @return object
+     * @throws Exception
+     */
+    protected function getNode($xmlObject, $nodeName)
+    {
+        if ($xmlObject != null) {
+            return $xmlObject->getElementsByTagName($nodeName);
+        }
+        Mage::throwException(Mage::helper('Dataflow')->__('Invalid node.'));
+    }
 }
diff --git app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
index 972545aca8f..98e979245ab 100644
--- app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
+++ app/code/core/Mage/Eav/Model/Entity/Attribute/Backend/Abstract.php
@@ -181,6 +181,15 @@ abstract class Mage_Eav_Model_Entity_Attribute_Backend_Abstract implements Mage_
             return false;
         }
 
+        //Validate serialized data
+        if (!Mage::helper('core/string')->validateSerializedObject($value)) {
+            $label = $this->getAttribute()->getFrontend()->getLabel();
+            throw Mage::exception(
+                'Mage_Eav',
+                Mage::helper('eav')->__('The value of attribute "%s" contains invalid data.', $label)
+            );
+        }
+
         if ($this->getAttribute()->getIsUnique() && !$this->getAttribute()->getIsRequired() && ($value == '' || $this->getAttribute()->isValueEmpty($value))) {
             return true;
         }
diff --git app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
index c0518bbe5ec..5f1ff6daa4c 100644
--- app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Adapter/Abstract.php
@@ -174,4 +174,14 @@ abstract class Mage_ImportExport_Model_Import_Adapter_Abstract implements Seekab
     {
         return $this;
     }
+
+    /**
+     * Get the source path
+     *
+     * @return string
+     */
+    public function getSource()
+    {
+        return $this->_source;
+    }
 }
diff --git app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
index e793a876a6e..da195c5fb53 100644
--- app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
+++ app/code/core/Mage/ImportExport/Model/Import/Entity/Abstract.php
@@ -662,6 +662,7 @@ abstract class Mage_ImportExport_Model_Import_Entity_Abstract
         if (!$this->_dataValidated) {
             // does all permanent columns exists?
             if (($colsAbsent = array_diff($this->_permanentAttributes, $this->_getSource()->getColNames()))) {
+                file_put_contents($this->_getSource()->getSource(), "");
                 Mage::throwException(
                     Mage::helper('importexport')->__('Can not find required columns: %s', implode(', ', $colsAbsent))
                 );
diff --git app/code/core/Mage/Install/Block/Admin.php app/code/core/Mage/Install/Block/Admin.php
index 44a8e8ab7d5..31776add243 100644
--- app/code/core/Mage/Install/Block/Admin.php
+++ app/code/core/Mage/Install/Block/Admin.php
@@ -51,4 +51,14 @@ class Mage_Install_Block_Admin extends Mage_Install_Block_Abstract
         }
         return $data;
     }
+
+    /**
+     * Retrieve minimum length of admin password
+     *
+     * @return int
+     */
+    public function getMinAdminPasswordLength()
+    {
+        return Mage::getModel('admin/user')->getMinAdminPasswordLength();
+    }
 }
diff --git app/code/core/Mage/Install/etc/config.xml app/code/core/Mage/Install/etc/config.xml
index 0f358d7e2a3..405276fff97 100644
--- app/code/core/Mage/Install/etc/config.xml
+++ app/code/core/Mage/Install/etc/config.xml
@@ -54,6 +54,13 @@
                 </install>
             </routers>
         </web>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Install_Block_End/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
     </default>
     <stores>
         <default>
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 3ff179ce76a..4f3521632ad 100644
--- app/code/core/Mage/Review/controllers/ProductController.php
+++ app/code/core/Mage/Review/controllers/ProductController.php
@@ -298,7 +298,17 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
             $this->getLayout()->helper('page/layout')
                 ->applyTemplate($product->getPageLayout());
         }
-        $update->addUpdate($product->getCustomLayoutUpdate());
+        $customLayout = $product->getCustomLayoutUpdate();
+        if ($customLayout) {
+            try {
+                if (!Mage::getModel('core/layout_validator')->isValid($customLayout)) {
+                    $customLayout = '';
+                }
+            } catch (Exception $e) {
+                $customLayout = '';
+            }
+        }
+        $update->addUpdate($customLayout);
         $this->generateLayoutXml()->generateLayoutBlocks();
     }
 
diff --git app/code/core/Mage/Rss/etc/config.xml app/code/core/Mage/Rss/etc/config.xml
index a8d89e7227e..e75e47e68b0 100644
--- app/code/core/Mage/Rss/etc/config.xml
+++ app/code/core/Mage/Rss/etc/config.xml
@@ -126,4 +126,13 @@
             </updates>
         </layout>
     </frontend>
+    <default>
+        <validators>
+            <custom_layout>
+                <disallowed_block>
+                    <Mage_Rss_Block_Order_New/>
+                </disallowed_block>
+            </custom_layout>
+        </validators>
+    </default>
 </config>
diff --git app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
index 750ff0339ff..e486b55f54e 100644
--- app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
+++ app/code/core/Mage/Widget/controllers/Adminhtml/Widget/InstanceController.php
@@ -281,6 +281,17 @@ class Mage_Widget_Adminhtml_Widget_InstanceController extends Mage_Adminhtml_Con
         $this->getResponse()->setBody($templateChooser->toHtml());
     }
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     /**
      * Check is allowed access to action
      *
diff --git app/code/core/Mage/Wishlist/Block/Abstract.php app/code/core/Mage/Wishlist/Block/Abstract.php
index c3d2612ea6d..8889f9fc9a7 100644
--- app/code/core/Mage/Wishlist/Block/Abstract.php
+++ app/code/core/Mage/Wishlist/Block/Abstract.php
@@ -164,7 +164,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getItemRemoveUrl($product)
     {
-        return $this->_getHelper()->getRemoveUrl($product);
+        return $this->getItemRemoveUrlCustom($product);
     }
 
     /**
@@ -175,7 +175,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getItemAddToCartUrl($item)
     {
-        return $this->_getHelper()->getAddToCartUrl($item);
+        return $this->getItemAddToCartUrlCustom($item);
     }
 
     /**
@@ -197,7 +197,7 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
      */
     public function getAddToWishlistUrl($product)
     {
-        return $this->_getHelper()->getAddUrl($product);
+        return $this->getAddToWishlistUrlCustom($product);
     }
 
      /**
@@ -387,4 +387,49 @@ abstract class Mage_Wishlist_Block_Abstract extends Mage_Catalog_Block_Product_A
         }
         return parent::getProductUrl($product, $additional);
     }
+
+    /**
+     * Retrieve URL for adding Product to wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToWishlistUrlCustom($product, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getAddUrlWithCustomParams($product, array(), false);
+        }
+        return $this->_getHelper()->getAddUrl($product);
+    }
+
+    /**
+     * Retrieve URL for Removing item from wishlist with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getItemRemoveUrlCustom($item, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getRemoveUrlCustom($item, false);
+        }
+        return $this->_getHelper()->getRemoveUrl($item);
+    }
+
+    /**
+     * Retrieve Add Item to shopping cart URL with or without Form Key
+     *
+     * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getItemAddToCartUrlCustom($item, $addFormKey = true)
+    {
+        if (!$addFormKey) {
+            return $this->_getHelper()->getAddToCartUrlCustom($item, false);
+        }
+        return $this->_getHelper()->getAddToCartUrl($item);
+    }
 }
diff --git app/code/core/Mage/Wishlist/Block/Share/Email/Items.php app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
index 614f4591692..a47c9dcc92e 100644
--- app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
+++ app/code/core/Mage/Wishlist/Block/Share/Email/Items.php
@@ -65,9 +65,22 @@ class Mage_Wishlist_Block_Share_Email_Items extends Mage_Wishlist_Block_Abstract
      * @return string
      */
     public function getAddToCartUrl($product, $additional = array())
+    {
+        return $this->getAddToCartUrlCustom($product, $additional);
+    }
+
+    /**
+     * Retrieve URL for add product to shopping cart with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product $product
+     * @param array $additional
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getAddToCartUrlCustom($product, $additional = array(), $addFormKey = true)
     {
         $additional['nocookie'] = 1;
         $additional['_store_to_url'] = true;
-        return parent::getAddToCartUrl($product, $additional);
+        return parent::getAddToCartUrlCustom($product, $additional, $addFormKey);
     }
 }
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index 441f40702a2..9e8128122e6 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -225,12 +225,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getRemoveUrl($item)
     {
-        return $this->_getUrl('wishlist/index/remove',
-            array(
-                'item' => $item->getWishlistItemId(),
-                Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-            )
-        );
+        return $this->getRemoveUrlCustom($item);
     }
 
     /**
@@ -290,20 +285,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getAddUrlWithParams($item, array $params = array())
     {
-        $productId = null;
-        if ($item instanceof Mage_Catalog_Model_Product) {
-            $productId = $item->getEntityId();
-        }
-        if ($item instanceof Mage_Wishlist_Model_Item) {
-            $productId = $item->getProductId();
-        }
-
-        if (!$productId) {
-            return false;
-        }
-        $params['product'] = $productId;
-        $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
-        return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        return $this->getAddUrlWithCustomParams($item, $params);
     }
 
     /**
@@ -314,20 +296,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
      */
     public function getAddToCartUrl($item)
     {
-        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
-            $this->_getUrl('*/*/*', array(
-                '_current'      => true,
-                '_use_rewrite'  => true,
-                '_store_to_url' => true,
-            ))
-        );
-        $params = array(
-            'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
-            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
-        );
-
-        return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
+        return $this->getAddToCartUrlCustom($item);
     }
 
     /**
@@ -500,4 +469,78 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         Mage::dispatchEvent('wishlist_items_renewed');
         return $this;
     }
+
+    /**
+     * Retrieve url for adding product to wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param array $params
+     * @param bool $addFormKey
+     * @return string|bool
+     */
+    public function getAddUrlWithCustomParams($item, array $params = array(), $addFormKey = true)
+    {
+        $productId = null;
+        if ($item instanceof Mage_Catalog_Model_Product) {
+            $productId = $item->getEntityId();
+        }
+        if ($item instanceof Mage_Wishlist_Model_Item) {
+            $productId = $item->getProductId();
+        }
+
+        if ($productId) {
+            $params['product'] = $productId;
+            if ($addFormKey) {
+                $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+            }
+            return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        }
+
+        return false;
+    }
+
+    /**
+     * Retrieve URL for removing item from wishlist with params with or without Form Key
+     *
+     * @param Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return string
+     */
+    public function getRemoveUrlCustom($item, $addFormKey = true)
+    {
+        $params = array(
+            'item' => $item->getWishlistItemId()
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+
+        return $this->_getUrl('wishlist/index/remove', $params);
+    }
+
+    /**
+     * Retrieve URL for adding item to shopping cart with or without Form Key
+     *
+     * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
+     * @param bool $addFormKey
+     * @return  string
+     */
+    public function getAddToCartUrlCustom($item, $addFormKey = true)
+    {
+        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
+            $this->_getUrl('*/*/*', array(
+                '_current'      => true,
+                '_use_rewrite'  => true,
+                '_store_to_url' => true,
+            ))
+        );
+        $params = array(
+            'item' => is_string($item) ? $item : $item->getWishlistItemId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+        );
+        if ($addFormKey) {
+            $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        }
+        return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
+    }
 }
diff --git app/design/frontend/base/default/template/catalog/product/list.phtml app/design/frontend/base/default/template/catalog/product/list.phtml
index 2070f25a705..1a030466816 100644
--- app/design/frontend/base/default/template/catalog/product/list.phtml
+++ app/design/frontend/base/default/template/catalog/product/list.phtml
@@ -34,6 +34,7 @@
 <?php
     $_productCollection=$this->getLoadedProductCollection();
     $_helper = $this->helper('catalog/output');
+    $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey())));
 ?>
 <?php if(!$_productCollection->count()): ?>
 <p class="note-msg"><?php echo $this->__('There are no products matching the selection.') ?></p>
@@ -68,10 +69,26 @@
                     </div>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->helper('wishlist')->getAddUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->helper('wishlist')->getAddUrlWithCustomParams($_product, array(), false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
@@ -106,10 +123,26 @@
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->helper('wishlist')->getAddUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->helper('wishlist')->getAddUrlWithCustomParams($_product, array(), false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if($_compareUrl=$this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/catalog/product/new.phtml app/design/frontend/base/default/template/catalog/product/new.phtml
index 45c6bddffd9..1a4df232a7c 100644
--- app/design/frontend/base/default/template/catalog/product/new.phtml
+++ app/design/frontend/base/default/template/catalog/product/new.phtml
@@ -27,6 +27,7 @@
 <?php if (($_products = $this->getProductCollection()) && $_products->getSize()): ?>
 <h2 class="subtitle"><?php echo $this->__('New Products') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products->getItems() as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -38,16 +39,40 @@
                 <?php echo $this->getPriceHtml($_product, true, '-new') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/reports/home_product_compared.phtml app/design/frontend/base/default/template/reports/home_product_compared.phtml
index 9da33f984ac..24396861d4b 100644
--- app/design/frontend/base/default/template/reports/home_product_compared.phtml
+++ app/design/frontend/base/default/template/reports/home_product_compared.phtml
@@ -28,6 +28,7 @@
 <?php if ($_products = $this->getRecentlyComparedProducts()): ?>
 <h2 class="subtitle"><?php echo $this->__('Your Recently Compared') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -39,16 +40,39 @@
                 <?php echo $this->getPriceHtml($_product, true, '-home-compared') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit('<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/reports/home_product_viewed.phtml app/design/frontend/base/default/template/reports/home_product_viewed.phtml
index 8a8adcd2bc5..4946567126a 100644
--- app/design/frontend/base/default/template/reports/home_product_viewed.phtml
+++ app/design/frontend/base/default/template/reports/home_product_viewed.phtml
@@ -33,6 +33,7 @@
 <?php if ($_products = $this->getRecentlyViewedProducts()): ?>
 <h2 class="subtitle"><?php echo $this->__('Your Recently Viewed') ?></h2>
 <?php $_columnCount = $this->getColumnCount(); ?>
+<?php $_params = $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))); ?>
     <?php $i=0; foreach ($_products as $_product): ?>
         <?php if ($i++%$_columnCount==0): ?>
         <ul class="products-grid">
@@ -44,16 +45,39 @@
                 <?php echo $this->getPriceHtml($_product, true, '-home-viewed') ?>
                 <div class="actions">
                     <?php if($_product->isSaleable()): ?>
-                        <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getAddToCartUrl($_product) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                        <button type="button"
+                                title="<?php echo Mage::helper('core')->quoteEscape($this->__('Add to Cart')) ?>"
+                                class="button btn-cart"
+                                onclick="customFormSubmit(
+                                        '<?php echo $this->getAddToCartUrlCustom($_product, array(), false) ?>',
+                                        '<?php echo $_params ?>',
+                                        'post')">
+                            <span><span><?php echo $this->__('Add to Cart') ?></span></span>
+                        </button>
                     <?php else: ?>
                         <p class="availability out-of-stock"><span><?php echo $this->__('Out of stock') ?></span></p>
                     <?php endif; ?>
                     <ul class="add-to-links">
                         <?php if ($this->helper('wishlist')->isAllow()) : ?>
-                            <li><a href="<?php echo $this->getAddToWishlistUrl($_product) ?>" class="link-wishlist"><?php echo $this->__('Add to Wishlist') ?></a></li>
-                        <?php endif; ?>
-                        <?php if ($_compareUrl = $this->getAddToCompareUrl($_product)): ?>
-                            <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+                            <?php $_wishlistUrl = $this->getAddToWishlistUrlCustom($_product, false); ?>
+                            <li>
+                                <a href="#"
+                                   data-url="<?php echo $_wishlistUrl ?>"
+                                   data-params="<?php echo $_params ?>"
+                                   class="link-wishlist"
+                                   onclick="customFormSubmit('<?php echo $_wishlistUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Wishlist') ?>
+                                </a>
+                            </li>                        <?php endif; ?>
+                        <?php if ($_compareUrl = $this->getAddToCompareUrlCustom($_product, false)) : ?>
+                            <li>
+                                <span class="separator">|</span>
+                                <a href="#"
+                                   class="link-compare"
+                                   onclick="customFormSubmit('<?php echo $_compareUrl ?>', '<?php echo $_params ?>', 'post')">
+                                    <?php echo $this->__('Add to Compare') ?>
+                                </a>
+                            </li>
                         <?php endif; ?>
                     </ul>
                 </div>
diff --git app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
index ab22c3f3c88..8e3eb578224 100644
--- app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
+++ app/design/frontend/base/default/template/wishlist/item/configure/addto.phtml
@@ -32,8 +32,18 @@
     <li><a href="<?php echo $_wishlistSubmitUrl ?>" onclick="productAddToCartForm.submitLight(this, '<?php echo $_wishlistSubmitUrl ?>'); return false;" class="link-wishlist"><?php echo $this->__('Update Wishlist') ?></a></li>
 <?php endif; ?>
 <?php $_product = $this->getProduct(); ?>
-<?php $_compareUrl = $this->helper('catalog/product_compare')->getAddUrl($_product); ?>
+<?php $_compareUrl = $this->helper('catalog/product_compare')->getAddUrlCustom($_product, false); ?>
 <?php if ($_compareUrl) : ?>
-    <li><span class="separator">|</span> <a href="<?php echo $_compareUrl ?>" class="link-compare"><?php echo $this->__('Add to Compare') ?></a></li>
+    <li>
+        <span class="separator">|</span>
+        <a href="#"
+           class="link-compare"
+           onclick="customFormSubmit(
+                   '<?php echo $_compareUrl ?>',
+                   '<?php echo $this->escapeHtml(json_encode(array('form_key' => $this->getFormKey()))) ?>',
+                   'post')">
+            <?php echo $this->__('Add to Compare') ?>
+        </a>
+    </li>
 <?php endif; ?>
 </ul>
diff --git app/design/install/default/default/template/install/create_admin.phtml app/design/install/default/default/template/install/create_admin.phtml
index 0826e53caf8..019c981d691 100644
--- app/design/install/default/default/template/install/create_admin.phtml
+++ app/design/install/default/default/template/install/create_admin.phtml
@@ -68,7 +68,18 @@
                 <label for="password"><?php echo $this->__('Password') ?> <span class="required">*</span></label><br/>
                 <!-- This is a dummy hidden field to trick firefox from auto filling the password -->
                 <input type="password" class="input-text" name="dummy" id="dummy" style="display: none;"/>
-                <input type="password" name="admin[new_password]" id="password" title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>" class="required-entry validate-admin-password input-text" autocomplete="new-password"/>
+                <?php $minAdminPasswordLength = $this->getMinAdminPasswordLength(); ?>
+                <input type="password"
+                       name="admin[new_password]"
+                       id="password"
+                       title="<?php echo Mage::helper('core')->quoteEscape($this->__('Password')) ?>"
+                       class="required-entry validate-admin-password input-text min-admin-pass-length-<?php echo $minAdminPasswordLength ?>"
+                       autocomplete="new-password"/>
+                <p class="note">
+                    <span>
+                        <?php echo Mage::helper('adminhtml')->__('Password must be at least of %d characters.', $minAdminPasswordLength) ?>
+                    </span>
+                </p>
             </div>
             <div class="input-box">
                 <label for="confirmation"><?php echo $this->__('Confirm Password') ?> <span
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 505225945e3..ff269526f6a 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -427,6 +427,8 @@
 "Helper attributes should not be used in custom layout updates.","Helper attributes should not be used in custom layout updates."
 "Helper for options rendering doesn't implement required interface.","Helper for options rendering doesn't implement required interface."
 "Home","Home"
+"Key %s does not contain scalar value","Key %s does not contain scalar value"
+"Key %s does not exist in array","Key %s does not exist in array"
 "ID","ID"
 "ID Path","ID Path"
 "IP Address","IP Address"
@@ -1183,6 +1185,7 @@
 "Wishlist item is not loaded.","Wishlist item is not loaded."
 "Wrong billing agreement ID specified.","Wrong billing agreement ID specified."
 "Wrong column format.","Wrong column format."
+"Wrong field specified.","Wrong field specified."
 "Wrong newsletter template.","Wrong newsletter template."
 "Wrong quote item.","Wrong quote item."
 "Wrong tab configuration.","Wrong tab configuration."
diff --git app/locale/en_US/Mage_Api.csv app/locale/en_US/Mage_Api.csv
index d79807793cb..0a1d0ad8cc8 100644
--- app/locale/en_US/Mage_Api.csv
+++ app/locale/en_US/Mage_Api.csv
@@ -424,3 +424,11 @@
 "of %s pages","of %s pages"
 "per page","per page"
 "to","to"
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
+"Api Key confirmation must be same as Api Key.","Api Key confirmation must be same as Api Key."
+"Api Key must be at least of %d characters.","Api Key must be at least of %d characters."
+"Api Key must include both numeric and alphabetic characters.","Api Key must include both numeric and alphabetic characters."
+"First Name is required field.","First Name is required field."
+"Last Name is required field.","Last Name is required field."
+"Please enter a valid email.","Please enter a valid email."
+"User Name is required field.","User Name is required field."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 951f1ea68e6..863455938fe 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -48,6 +48,7 @@
 "Can't retrieve request object","Can't retrieve request object"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed block name for frontend.","Disallowed block name for frontend."
 "Disallowed template variable method.","Disallowed template variable method."
 "Cannot retrieve entity config: %s","Cannot retrieve entity config: %s"
 "Card type does not match credit card number.","Card type does not match credit card number."
@@ -127,8 +128,10 @@
 "General Contact","General Contact"
 "General Settings","General Settings"
 "Global","Global"
+"HTML filtration has failed.","HTML filtration has failed."
 "HTML Head","HTML Head"
 "Header","Header"
+"Helper attributes should not be used in custom layout updates.","Helper attributes should not be used in custom layout updates."
 "Host","Host"
 "How many links to display at once.","How many links to display at once."
 "ID Path for Specified Store","ID Path for Specified Store"
@@ -143,6 +146,7 @@
 "Invalid layout update handle","Invalid layout update handle"
 "Invalid messages storage ""%s"" for layout messages initialization","Invalid messages storage ""%s"" for layout messages initialization"
 "Invalid stream.","Invalid stream."
+"Invalid template path used in layout update.","Invalid template path used in layout update."
 "Invalid query","Invalid query"
 "Invalid transactional email code: ","Invalid transactional email code: "
 "Invalid website\'s configuration path: %s","Invalid website\'s configuration path: %s"
@@ -172,6 +176,7 @@
 "Module ""%1$s"" cannot depend on ""%2$s"".","Module ""%1$s"" cannot depend on ""%2$s""."
 "Module ""%1$s"" requires module ""%2$s"".","Module ""%1$s"" requires module ""%2$s""."
 "Name","Name"
+"File name is too long. Maximum length is %s.","File name is too long. Maximum length is %s."
 "New Design Change","New Design Change"
 "New Store","New Store"
 "New Store View","New Store View"
@@ -216,6 +221,8 @@
 "Please enter a valid zip code.","Please enter a valid zip code."
 "Please enter a valid zip code. For example 90602 or 90602-1234.","Please enter a valid zip code. For example 90602 or 90602-1234."
 "Please enter issue number or start date for switch/solo card type.","Please enter issue number or start date for switch/solo card type."
+"Please enter more characters or clean leading or trailing spaces.","Please enter more characters or clean leading or trailing spaces."
+"Please enter more characters. Password should contain both numeric and alphabetic characters.","Please enter more characters. Password should contain both numeric and alphabetic characters."
 "Please enter valid password.","Please enter valid password."
 "Please input a valid CSS-length. For example 100px or 77pt or 20em or .5ex or 50%.","Please input a valid CSS-length. For example 100px or 77pt or 20em or .5ex or 50%."
 "Please make sure your passwords match.","Please make sure your passwords match."
@@ -367,3 +374,5 @@
 "Your session has been expired, you will be relogged in now.","Your session has been expired, you will be relogged in now."
 "database ""%s""","database ""%s"""
 "Invalid image.","Invalid image."
+"XML data is invalid.","XML data is invalid."
+"XML object is not instance of ""Varien_Simplexml_Element"".","XML object is not instance of ""Varien_Simplexml_Element""."
diff --git app/locale/en_US/Mage_Customer.csv app/locale/en_US/Mage_Customer.csv
index 18b33049387..e24fe408b56 100644
--- app/locale/en_US/Mage_Customer.csv
+++ app/locale/en_US/Mage_Customer.csv
@@ -220,6 +220,8 @@
 "MM","MM"
 "Manage Addresses","Manage Addresses"
 "Manage Customers","Manage Customers"
+"Minimum admin password length","Minimum admin password length"
+"Minimum password length","Minimum password length"
 "Missing email, skipping the record.","Missing email, skipping the record."
 "Missing firstname, skipping the record.","Missing firstname, skipping the record."
 "Missing lastname, skipping the record.","Missing lastname, skipping the record."
@@ -376,6 +378,7 @@
 "The customer group has been saved.","The customer group has been saved."
 "The group ""%s"" cannot be deleted.","The group ""%s"" cannot be deleted."
 "The password must have at least 6 characters. Leading or trailing spaces will be ignored.","The password must have at least 6 characters. Leading or trailing spaces will be ignored."
+"The password must have at least %d characters. Leading or trailing spaces will be ignored.","The password must have at least %d characters. Leading or trailing spaces will be ignored."
 "The suffix that goes after name (Jr., Sr., etc.)","The suffix that goes after name (Jr., Sr., etc.)"
 "The title that goes before name (Mr., Mrs., etc.)","The title that goes before name (Mr., Mrs., etc.)"
 "There are no items in customer's wishlist at the moment","There are no items in customer's wishlist at the moment"
@@ -438,3 +441,4 @@
 "Zip/Postal Code","Zip/Postal Code"
 "n/a","n/a"
 "or","or"
+"Please enter a number 7 or greater in this field.","Please enter a number 7 or greater in this field."
diff --git app/locale/en_US/Mage_Dataflow.csv app/locale/en_US/Mage_Dataflow.csv
index 79b33f50846..335890af381 100644
--- app/locale/en_US/Mage_Dataflow.csv
+++ app/locale/en_US/Mage_Dataflow.csv
@@ -1,4 +1,5 @@
 "<a href=""%s"" target=""_blank"">Link</a>","<a href=""%s"" target=""_blank"">Link</a>"
+"Upload failed. Can not find required columns: %s in file %s.", "Upload failed. Can not find required columns: %s in file %s."
 "An error occurred while opening file: ""%s"".","An error occurred while opening file: ""%s""."
 "Could not load file: ""%s"".","Could not load file: ""%s""."
 "Could not save file: %s.","Could not save file: %s."
@@ -11,6 +12,7 @@
 "Error in field mapping: field list for mapping is not defined.","Error in field mapping: field list for mapping is not defined."
 "File ""%s"" does not exist.","File ""%s"" does not exist."
 "Found %d rows.","Found %d rows."
+"Invalid node.", "Invalid node."
 "Less than a minute","Less than a minute"
 "Loaded successfully: ""%s"".","Loaded successfully: ""%s""."
 "Memory Used: %s","Memory Used: %s"
@@ -24,6 +26,7 @@
 "Starting %s :: %s","Starting %s :: %s"
 "The destination folder ""%s"" does not exist or there is no access to create it.","The destination folder ""%s"" does not exist or there is no access to create it."
 "Total records: %s","Total records: %s"
+"Upload failed. Wrong data format in file: %s.","Upload failed. Wrong data format in file: %s."
 "hour","hour"
 "hours","hours"
 "minute","minute"
diff --git app/locale/en_US/Mage_Eav.csv app/locale/en_US/Mage_Eav.csv
index c3f84121841..49d10de2f0e 100644
--- app/locale/en_US/Mage_Eav.csv
+++ app/locale/en_US/Mage_Eav.csv
@@ -80,3 +80,4 @@
 "Wrong entity ID.","Wrong entity ID."
 "Yes","Yes"
 "Yes/No","Yes/No"
+"The value of attribute ""%s"" contains invalid data.","The value of attribute ""%s"" contains invalid data."
diff --git app/locale/en_US/Mage_XmlConnect.csv app/locale/en_US/Mage_XmlConnect.csv
index 3aadafe700d..6c1a44ff82f 100644
--- app/locale/en_US/Mage_XmlConnect.csv
+++ app/locale/en_US/Mage_XmlConnect.csv
@@ -532,3 +532,4 @@
 "iPad","iPad"
 "iPhone","iPhone"
 "save","save"
+"The minimum password length is ","The minimum password length is "
diff --git js/mage/adminhtml/variables.js js/mage/adminhtml/variables.js
index cec1f9e43d4..5c63d9bbc38 100644
--- js/mage/adminhtml/variables.js
+++ js/mage/adminhtml/variables.js
@@ -105,7 +105,7 @@ var Variables = {
         }
     },
     prepareVariableRow: function(varValue, varLabel) {
-        var value = (varValue).replace(/"/g, '&quot;').replace(/'/g, '\\&#39;');
+        var value = (varValue).replace(/"/g, '&quot;').replace(/\\/g, '\\\\').replace(/'/g, '\\&#39;');
         var content = '<a href="#" onclick="'+this.insertFunction+'(\''+ value +'\');">' + varLabel + '</a>';
         return content;
     },
diff --git js/prototype/validation.js js/prototype/validation.js
index f9d1fddefd8..45066a70a88 100644
--- js/prototype/validation.js
+++ js/prototype/validation.js
@@ -470,11 +470,18 @@ Validation.addAllThese([
     ['validate-emailSender', 'Please use only visible characters and spaces.', function (v) {
                 return Validation.get('IsEmpty').test(v) ||  /^[\S ]+$/.test(v)
                     }],
-    ['validate-password', 'Please enter 6 or more characters. Leading or trailing spaces will be ignored.', function(v) {
+    ['validate-password', 'Please enter more characters or clean leading or trailing spaces.', function(v, elm) {
                 var pass=v.strip(); /*strip leading and trailing spaces*/
-                return !(pass.length>0 && pass.length < 6);
+                var reMin = new RegExp(/^min-pass-length-[0-9]+$/);
+                var minLength = 7;
+                $w(elm.className).each(function(name, index) {
+                    if (name.match(reMin)) {
+                        minLength = name.split('-')[3];
+                    }
+                });
+                return (!(v.length > 0 && v.length < minLength) && v.length == pass.length);
             }],
-    ['validate-admin-password', 'Please enter 7 or more characters. Password should contain both numeric and alphabetic characters.', function(v) {
+    ['validate-admin-password', 'Please enter more characters. Password should contain both numeric and alphabetic characters.', function(v, elm) {
                 var pass=v.strip();
                 if (0 == pass.length) {
                     return true;
@@ -482,7 +489,14 @@ Validation.addAllThese([
                 if (!(/[a-z]/i.test(v)) || !(/[0-9]/.test(v))) {
                     return false;
                 }
-                return !(pass.length < 7);
+                var reMin = new RegExp(/^min-admin-pass-length-[0-9]+$/);
+                var minLength = 7;
+                $w(elm.className).each(function(name, index) {
+                    if (name.match(reMin)) {
+                        minLength = name.split('-')[4];
+                    }
+                });
+                return !(pass.length < minLength);
             }],
     ['validate-cpassword', 'Please make sure your passwords match.', function(v) {
                 var conf = $('confirmation') ? $('confirmation') : $$('.validate-cpassword')[0];
@@ -575,8 +589,8 @@ Validation.addAllThese([
                 return (v!=0 || v == '');
             }],
 
-    ['validate-new-password', 'Please enter 6 or more characters. Leading or trailing spaces will be ignored.', function(v) {
-                if (!Validation.get('validate-password').test(v)) return false;
+    ['validate-new-password', 'Please enter more characters or clean leading or trailing spaces.', function(v, elm) {
+                if (!Validation.get('validate-password').test(v, elm)) return false;
                 if (Validation.get('IsEmpty').test(v) && v != '') return false;
                 return true;
             }],
diff --git js/varien/js.js js/varien/js.js
index 6d10f7f2028..96f1e39ea4b 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -698,3 +698,19 @@ function customFormSubmit(url, parametersArray, method) {
     Element.insert($$('body')[0], createdForm.form);
     createdForm.form.submit();
 }
+
+function customFormSubmitToParent(url, parametersArray, method) {
+    new Ajax.Request(url, {
+        method: method,
+        parameters: JSON.parse(parametersArray),
+        onSuccess: function (response) {
+            var node = document.createElement('div');
+            node.innerHTML = response.responseText;
+            var responseMessage = node.getElementsByClassName('messages')[0];
+            var pageTitle = window.document.body.getElementsByClassName('page-title')[0];
+            pageTitle.insertAdjacentHTML('afterend', responseMessage.outerHTML);
+            window.opener.focus();
+            window.opener.location.href = response.transport.responseURL;
+        }
+    });
+}
diff --git lib/Varien/Filter/FormElementName.php lib/Varien/Filter/FormElementName.php
index 888e1e9fff7..da37a369d11 100644
--- lib/Varien/Filter/FormElementName.php
+++ lib/Varien/Filter/FormElementName.php
@@ -1,12 +1,29 @@
 <?php
 /**
- * {license_notice}
+ * Magento
  *
- * @copyright   {copyright}
- * @license     {license_link}
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Open Software License (OSL 3.0)
+ * that is bundled with this package in the file LICENSE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://opensource.org/licenses/osl-3.0.php
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Varien
+ * @package     Varien_Filter
+ * @copyright  Copyright (c) 2006-2019 Magento, Inc. (http://www.magento.com)
+ * @license    http://opensource.org/licenses/osl-3.0.php  Open Software License (OSL 3.0)
  */
 
-
 class Varien_Filter_FormElementName extends Zend_Filter_Alnum
 {
     /**
diff --git skin/adminhtml/default/default/boxes.css skin/adminhtml/default/default/boxes.css
index b58e3fe141c..fe827a82453 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -1399,6 +1399,7 @@ ul.super-product-attributes { padding-left:15px; }
 .wrap               { white-space:normal !important; }
 .no-float           { float:none !important; }
 .pointer            { cursor:pointer; }
+.half               { width:50%; }
 
 /* Color */
 .emph, .accent      { color:#eb5e00 !important; }
