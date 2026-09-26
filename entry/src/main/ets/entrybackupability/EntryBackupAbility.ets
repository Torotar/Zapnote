import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;
const TAG = 'ZapNoteBackup';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    hilog.info(DOMAIN, TAG, 'System backup preparation completed');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, TAG, 'System restore completed for %{public}s', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}
