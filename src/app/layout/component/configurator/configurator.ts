import { CommonModule, isPlatformBrowser } from '@angular/common';
import { Component, computed, inject, PLATFORM_ID } from '@angular/core';
import Aura from '@primeuix/themes/aura';
import { LayoutService } from '../../../core/services/state/layout.service';
import { $t, updateSurfacePalette, updatePreset } from '@primeuix/themes';

const PRESET = Aura;
const PRIMARY_HEX = '#015cc0';

declare type SurfacesType = {
  name?: string;
  palette?: Record<string, string>;
};

@Component({
  selector: 'app-configurator',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './configurator.html',
  host: {
    class:
      'hidden absolute top-13 right-0 w-72 p-4 bg-surface-0 dark:bg-surface-900 border border-surface rounded-border origin-top shadow-[0px_3px_5px_rgba(0,0,0,0.02),0px_0px_2px_rgba(0,0,0,0.05),0px_1px_4px_rgba(0,0,0,0.08)]',
  },
})
export class Configurator {
  private layoutService = inject(LayoutService);
  private platformId = inject(PLATFORM_ID);

  // surface unique : zinc-white
  surfaces: SurfacesType[] = [
    {
      name: 'zinc-white',
      palette: {
        0: '#ffffff',
        50: '#fafafa',
        100: '#f4f4f5',
        200: '#e4e4e7',
        300: '#d4d4d8',
        400: '#a1a1aa',
        500: '#71717a',
        600: '#52525b',
        700: '#3f3f46',
        800: '#27272a',
        900: '#18181b',
        950: '#09090b',
      },
    },
  ];

  selectedPreset = computed(() => 'Aura');
  selectedSurfaceColor = computed(() => 'zinc-white');

  ngOnInit() {
    if (!isPlatformBrowser(this.platformId)) return;

    // 1) Forcer l'état global layout (Aura, zinc-white, overlay)
    this.layoutService.layoutConfig.update((state) => ({
      ...state,
      preset: 'Aura',
      surface: 'zinc-white',
      menuMode: 'static', // 'static' : Pour un menu fixe, 'overlay' : Pour un menu superposé, 'slim' ou 'horizontal'
      primary: 'custom',
    }));

    // 2) Appliquer la surface au moteur de thème PrimeUI
    const surfacePalette = this.surfaces[0].palette;
    $t().preset(PRESET).surfacePalette(surfacePalette).use({ useDefaultOptions: true });
    updateSurfacePalette(surfacePalette);

    // 3) Forcer la couleur primaire sémantique du preset (palette minimale)
    updatePreset({
      semantic: {
        primary: {
          400: '#2177d1',
          500: PRIMARY_HEX,
          600: '#014f9a',
        },
      },
    });

    // 4) Définir une variable CSS globale pour permettre l'utilisation directe dans les styles/templates
    document.documentElement.style.setProperty('--primary-color', PRIMARY_HEX);
    document.documentElement.style.setProperty('--primary-color-contrast', '#ffffff');
  }

  updateColors(event: Event, type: string, color: any) {
    if (type === 'surface') {
      this.layoutService.layoutConfig.update((state) => ({
        ...state,
        surface: color.name,
      }));
      updateSurfacePalette(color.palette);
    }
    event.stopPropagation();
  }
}
