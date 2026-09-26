import {
  BlurStrategy,
  DividerShowType,
  HdsNavigationIconItemStyle,
  HdsNavigationMenuItemOptions,
  HdsNavigationTitleBarOptions,
  ScrollEffectType,
  hdsMaterial
} from '@kit.UIDesignKit';

const SUB_TITLE_MASK_EXTRA_HEIGHT: number = 0;
const SUB_TITLE_BLUR_RADIUS: number = 28;
const TRANSPARENT_COLOR: string = '#00000000';

function createTitleIconStyle(titleColor: string,
  keepBackgroundTransparent: boolean): HdsNavigationIconItemStyle {
  const style: HdsNavigationIconItemStyle = {
    iconColor: titleColor,
    textColor: titleColor
  };
  if (keepBackgroundTransparent) {
    style.backgroundColor = TRANSPARENT_COLOR;
  }
  return style;
}

function getTitleMaterialType(materialEffectMode: number): hdsMaterial.MaterialType {
  if (materialEffectMode === 0) {
    return hdsMaterial.MaterialType.NONE;
  }
  if (materialEffectMode <= 2) {
    return hdsMaterial.MaterialType.ADAPTIVE;
  }
  try {
    const materialTypes: hdsMaterial.MaterialType[] = hdsMaterial.getSystemMaterialTypes();
    if (materialTypes.indexOf(hdsMaterial.MaterialType.IMMERSIVE) >= 0) {
      return hdsMaterial.MaterialType.IMMERSIVE;
    }
  } catch (error) {
  }
  return hdsMaterial.MaterialType.ADAPTIVE;
}

function getTitleMaterialLevel(materialEffectMode: number): hdsMaterial.MaterialLevel {
  if (materialEffectMode === 4) {
    return hdsMaterial.MaterialLevel.EXQUISITE;
  }
  if (materialEffectMode === 3) {
    return hdsMaterial.MaterialLevel.GENTLE;
  }
  if (materialEffectMode === 2) {
    return hdsMaterial.MaterialLevel.SMOOTH;
  }
  return hdsMaterial.MaterialLevel.ADAPTIVE;
}

export function createHdsSubPageTitleBarOptions(title: string, darkMode: boolean,
  materialEffectMode: number, onBack?: () => void,
  menuItems?: Array<HdsNavigationMenuItemOptions>, previewMode: boolean = false,
  stackBuilder?: CustomBuilder): HdsNavigationTitleBarOptions {
  const titleColor: string = darkMode ? '#F8FAFC' : '#1A1A2E';
  const transparentForPreview: boolean = title.length === 0 && darkMode;
  const materialEffectEnabled: boolean = materialEffectMode !== 0;
  const keepIconBackgroundTransparent: boolean = materialEffectMode <= 2 && !previewMode;
  const handleBack: () => void = (): void => {
    if (onBack !== undefined) {
      onBack();
    }
  };
  return {
    content: {
      title: {
        mainTitle: title
      },
      menu: menuItems !== undefined ? {
        value: menuItems,
        maxCount: menuItems.length
      } : undefined,
      backIcon: {
        isEnabled: true,
        action: handleBack
      },
      stackBuilder: stackBuilder,
      divider: {
        showType: DividerShowType.AUTO
      }
    },
    avoidLayoutSafeArea: true,
    enableComponentSafeArea: !previewMode,
    style: {
      scrollEffectOpts: {
        enableScrollEffect: materialEffectEnabled,
        scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
      },
      blurStrategy: materialEffectEnabled ? BlurStrategy.ENABLE : BlurStrategy.DISABLE,
      thermoCtrl: materialEffectEnabled,
      originalStyle: {
        backgroundStyle: {
          backgroundColor: TRANSPARENT_COLOR,
          maskExtraHeight: SUB_TITLE_MASK_EXTRA_HEIGHT,
          blurRadius: materialEffectEnabled ? SUB_TITLE_BLUR_RADIUS : 0
        },
        contentStyle: {
          titleStyle: {
            mainTitleColor: titleColor
          },
          backIconStyle: createTitleIconStyle(titleColor, keepIconBackgroundTransparent),
          menuStyle: createTitleIconStyle(titleColor, keepIconBackgroundTransparent)
        }
      },
      scrollEffectStyle: {
        backgroundStyle: {
          backgroundColor: transparentForPreview ? TRANSPARENT_COLOR :
            darkMode ? 'rgba(18, 20, 26, 0.52)' : 'rgba(245, 249, 255, 0.58)',
          maskExtraHeight: SUB_TITLE_MASK_EXTRA_HEIGHT,
          blurRadius: materialEffectEnabled ? SUB_TITLE_BLUR_RADIUS : 0
        },
        contentStyle: {
          titleStyle: {
            mainTitleColor: titleColor
          },
          backIconStyle: createTitleIconStyle(titleColor, keepIconBackgroundTransparent),
          menuStyle: createTitleIconStyle(titleColor, keepIconBackgroundTransparent),
          dividerStyle: {
            dividerColor: darkMode ? 'rgba(148, 163, 184, 0.18)' : 'rgba(148, 163, 184, 0.22)'
          }
        }
      },
      systemMaterialEffect: materialEffectEnabled ? {
        materialType: getTitleMaterialType(materialEffectMode),
        materialLevel: getTitleMaterialLevel(materialEffectMode)
      } : undefined
    }
  };
}
