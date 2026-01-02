import { ApiProperty } from '@nestjs/swagger';

export class RyvieTunnelInfoDto {
  @ApiProperty({ description: 'Whether the request was successful' })
  success!: boolean;

  @ApiProperty({ description: 'Unique Ryvie identifier', required: false })
  ryvieId?: string;

  @ApiProperty({ description: 'Tunnel host IP or hostname', required: false })
  tunnelHost?: string;

  @ApiProperty({ description: 'Public URL for external access', required: false })
  publicUrl?: string;

  @ApiProperty({ description: 'Domain configuration', required: false })
  domains?: {
    app?: string;
    api?: string;
  };

  @ApiProperty({ description: 'NetBird setup key', required: false })
  setupKey?: string;
}
